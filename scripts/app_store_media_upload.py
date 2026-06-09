from __future__ import annotations

import base64
import hashlib
import json
import os
import time
from pathlib import Path

import jwt
import requests


BASE_URL = "https://api.appstoreconnect.apple.com/v1"
APP_ID = os.environ["APP_STORE_APP_ID"].strip()
APP_VERSION = os.environ.get("APP_VERSION", "1.0").strip()
LOCALES = tuple(locale.strip() for locale in os.environ.get("APP_LOCALES", "en-GB,en-US").split(",") if locale.strip())
ROOT = Path(__file__).resolve().parents[1]
SCREENSHOT_ROOT = ROOT / "Screenshots" / "AppStore"

APP_SCREENSHOT_SETS = (
    ("APP_IPHONE_65", SCREENSHOT_ROOT / "iPhone_6.5_1242x2688"),
    ("APP_IPAD_PRO_3GEN_129", SCREENSHOT_ROOT / "iPad_13_2048x2732"),
)

SUBSCRIPTION_ASSETS = {
    "com.legacyvaultai.premium.monthly": {
        "promo": SCREENSHOT_ROOT / "Subscriptions" / "PromotionalImages_1024x1024" / "premium-monthly-promotional-image.png",
        "review": SCREENSHOT_ROOT / "Subscriptions" / "AppReviewScreenshots_1242x2688" / "premium-monthly-review-screenshot.png",
    },
    "com.legacyvaultai.premium.yearly": {
        "promo": SCREENSHOT_ROOT / "Subscriptions" / "PromotionalImages_1024x1024" / "premium-yearly-promotional-image.png",
        "review": SCREENSHOT_ROOT / "Subscriptions" / "AppReviewScreenshots_1242x2688" / "premium-yearly-review-screenshot.png",
    },
    "com.legacyvaultai.familyoffice.monthly": {
        "promo": SCREENSHOT_ROOT / "Subscriptions" / "PromotionalImages_1024x1024" / "family-office-monthly-promotional-image.png",
        "review": SCREENSHOT_ROOT / "Subscriptions" / "AppReviewScreenshots_1242x2688" / "family-office-monthly-review-screenshot.png",
    },
}


def private_key() -> str:
    private_key_value = os.environ.get("ASC_API_PRIVATE_KEY", "").strip()
    private_key_base64 = os.environ.get("ASC_API_PRIVATE_KEY_BASE64", "").strip()
    if private_key_base64:
        private_key_value = base64.b64decode(private_key_base64).decode("utf-8")
    elif private_key_value and "BEGIN PRIVATE KEY" not in private_key_value:
        decoded = base64.b64decode(private_key_value).decode("utf-8")
        if "BEGIN PRIVATE KEY" in decoded:
            private_key_value = decoded
    if "BEGIN PRIVATE KEY" not in private_key_value:
        raise RuntimeError("ASC_API_PRIVATE_KEY or ASC_API_PRIVATE_KEY_BASE64 is required.")
    return private_key_value


def make_session() -> requests.Session:
    key_id = os.environ["ASC_API_KEY_ID"].strip()
    issuer_id = os.environ["ASC_API_ISSUER_ID"].strip()
    if not key_id or not issuer_id:
        raise RuntimeError("ASC_API_KEY_ID and ASC_API_ISSUER_ID are required.")
    now = int(time.time())
    token = jwt.encode(
        {
            "iss": issuer_id,
            "iat": now - 60,
            "exp": now + 20 * 60,
            "aud": "appstoreconnect-v1",
        },
        private_key(),
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )
    session = requests.Session()
    session.headers.update(
        {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
    )
    return session


SESSION = make_session()


def request(method: str, path: str, payload: dict | None = None, params: dict | None = None) -> dict:
    response = SESSION.request(
        method,
        f"{BASE_URL}{path}",
        params=params,
        data=None if payload is None else json.dumps(payload),
        timeout=60,
    )
    if response.status_code >= 400:
        print(response.text)
        response.raise_for_status()
    if not response.text:
        return {}
    return response.json()


def delete(path: str) -> None:
    response = SESSION.delete(f"{BASE_URL}{path}", timeout=60)
    if response.status_code not in (200, 202, 204, 404):
        print(response.text)
        response.raise_for_status()


def upload_headers(operation: dict) -> dict[str, str]:
    headers = operation.get("requestHeaders") or []
    if isinstance(headers, dict):
        return {str(key): str(value) for key, value in headers.items()}
    return {str(item["name"]): str(item["value"]) for item in headers}


def upload_operations(operations: list[dict], data: bytes) -> None:
    for operation in operations:
        offset = int(operation.get("offset") or 0)
        length = int(operation.get("length") or len(data))
        chunk = data[offset : offset + length]
        response = requests.request(
            operation.get("method", "PUT"),
            operation["url"],
            headers=upload_headers(operation),
            data=chunk,
            timeout=120,
        )
        if response.status_code >= 400:
            print(response.text)
            response.raise_for_status()


def commit_asset(resource_type: str, resource_id: str, checksum: str) -> None:
    request(
        "PATCH",
        f"/{resource_type}/{resource_id}",
        {
            "data": {
                "type": resource_type,
                "id": resource_id,
                "attributes": {
                    "uploaded": True,
                    "sourceFileChecksum": checksum,
                },
            }
        },
    )


def delivery_state(attributes: dict) -> str | None:
    state = attributes.get("assetDeliveryState") or attributes.get("state")
    if isinstance(state, dict):
        return state.get("state")
    if isinstance(state, str):
        return state
    return None


def wait_for_complete(resource_type: str, resource_id: str, timeout_seconds: int = 420) -> str:
    deadline = time.time() + timeout_seconds
    last_state = "UNKNOWN"
    while time.time() < deadline:
        payload = request("GET", f"/{resource_type}/{resource_id}")
        attrs = payload["data"].get("attributes", {})
        last_state = delivery_state(attrs) or last_state
        if last_state == "COMPLETE":
            return last_state
        if last_state == "FAILED":
            raise RuntimeError(f"{resource_type} {resource_id} processing failed: {attrs}")
        time.sleep(8)
    raise RuntimeError(f"{resource_type} {resource_id} did not complete processing. Last state: {last_state}")


def upload_reserved_asset(resource_type: str, resource_id: str, attributes: dict, path: Path) -> None:
    data = path.read_bytes()
    operations = attributes.get("uploadOperations") or []
    if not operations:
        raise RuntimeError(f"No upload operations returned for {path}.")
    upload_operations(operations, data)
    commit_asset(resource_type, resource_id, hashlib.md5(data).hexdigest())
    final_state = wait_for_complete(resource_type, resource_id)
    print(f"Uploaded {path.name} -> {resource_type} {resource_id} ({final_state})")


def app_store_version_localization_id() -> str:
    versions_payload = request(
        "GET",
        f"/apps/{APP_ID}/appStoreVersions",
        params={
            "filter[platform]": "IOS",
            "filter[versionString]": APP_VERSION,
            "include": "appStoreVersionLocalizations",
            "limit": "10",
        },
    )
    versions = versions_payload.get("data", [])
    if not versions:
        raise RuntimeError(f"No iOS {APP_VERSION} appStoreVersion was returned.")
    localizations = [
        item
        for item in versions_payload.get("included", [])
        if item.get("type") == "appStoreVersionLocalizations"
    ]
    if not localizations:
        localizations = request(
            "GET",
            f"/appStoreVersions/{versions[0]['id']}/appStoreVersionLocalizations",
            params={"limit": "10"},
        ).get("data", [])
    if not localizations:
        raise RuntimeError(f"No iOS {APP_VERSION} localization was returned.")
    selected = next(
        (
            item
            for locale in LOCALES
            for item in localizations
            if item.get("attributes", {}).get("locale") == locale
        ),
        localizations[0],
    )
    print(f"Using app version localization {selected['id']} ({selected.get('attributes', {}).get('locale')}).")
    return selected["id"]


def create_screenshot_set(localization_id: str, display_type: str) -> str:
    existing = request(
        "GET",
        f"/appStoreVersionLocalizations/{localization_id}/appScreenshotSets",
        params={"filter[screenshotDisplayType]": display_type, "limit": "200"},
    ).get("data", [])
    for screenshot_set in existing:
        delete(f"/appScreenshotSets/{screenshot_set['id']}")
        print(f"Deleted existing screenshot set {screenshot_set['id']} ({display_type}).")
    payload = request(
        "POST",
        "/appScreenshotSets",
        {
            "data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": display_type},
                "relationships": {
                    "appStoreVersionLocalization": {
                        "data": {"type": "appStoreVersionLocalizations", "id": localization_id}
                    }
                },
            }
        },
    )
    screenshot_set_id = payload["data"]["id"]
    print(f"Created screenshot set {screenshot_set_id} ({display_type}).")
    return screenshot_set_id


def upload_app_screenshot(screenshot_set_id: str, path: Path) -> str:
    data_size = path.stat().st_size
    payload = request(
        "POST",
        "/appScreenshots",
        {
            "data": {
                "type": "appScreenshots",
                "attributes": {"fileSize": data_size, "fileName": path.name},
                "relationships": {
                    "appScreenshotSet": {
                        "data": {"type": "appScreenshotSets", "id": screenshot_set_id}
                    }
                },
            }
        },
    )
    screenshot_id = payload["data"]["id"]
    upload_reserved_asset("appScreenshots", screenshot_id, payload["data"]["attributes"], path)
    return screenshot_id


def upload_app_screenshot_sets(localization_id: str) -> None:
    for display_type, directory in APP_SCREENSHOT_SETS:
        images = [path for path in sorted(directory.glob("*.png")) if path.name != "contact-sheet.png"]
        if not images:
            raise RuntimeError(f"No screenshots found in {directory}.")
        screenshot_set_id = create_screenshot_set(localization_id, display_type)
        screenshot_ids = [upload_app_screenshot(screenshot_set_id, path) for path in images]
        request(
            "PATCH",
            f"/appScreenshotSets/{screenshot_set_id}/relationships/appScreenshots",
            {"data": [{"type": "appScreenshots", "id": screenshot_id} for screenshot_id in screenshot_ids]},
        )
        print(f"Uploaded {len(screenshot_ids)} screenshots for {display_type}.")


def in_app_purchase_id(product_id: str) -> str:
    payload = request(
        "GET",
        f"/apps/{APP_ID}/inAppPurchasesV2",
        params={"filter[productId]": product_id, "limit": "10"},
    )
    purchases = payload.get("data", [])
    if purchases:
        return purchases[0]["id"]

    all_purchases = request("GET", f"/apps/{APP_ID}/inAppPurchasesV2", params={"limit": "200"}).get("data", [])
    if not all_purchases:
        raise RuntimeError("No in-app purchases were returned for the app.")

    print("Available in-app purchases:")
    for purchase in all_purchases:
        attrs = purchase.get("attributes", {})
        print(
            "-",
            purchase["id"],
            attrs.get("productId"),
            attrs.get("name") or attrs.get("referenceName"),
        )

    target_tokens = product_id.replace("familyoffice", "family.office").replace("_", ".").split(".")
    target_tokens = [token for token in target_tokens if token not in {"com", "legacyvaultai"}]

    def score(purchase: dict) -> int:
        attrs = purchase.get("attributes", {})
        haystack = " ".join(
            str(attrs.get(field, ""))
            for field in ("productId", "name", "referenceName")
        ).lower().replace("_", " ").replace("-", " ").replace(".", " ")
        return sum(1 for token in target_tokens if token.lower() in haystack)

    best = max(all_purchases, key=score)
    best_score = score(best)
    if best_score < 2:
        raise RuntimeError(f"No in-app purchase found for {product_id}.")

    attrs = best.get("attributes", {})
    print(
        f"Matched {product_id} to {attrs.get('productId')} "
        f"({attrs.get('name') or attrs.get('referenceName')}) by App Store Connect metadata."
    )
    return best["id"]


def clear_iap_images(iap_id: str) -> None:
    images = request("GET", f"/inAppPurchases/{iap_id}/images", params={"limit": "200"}).get("data", [])
    for image in images:
        delete(f"/inAppPurchaseImages/{image['id']}")
        print(f"Deleted existing promotional image {image['id']}.")


def clear_iap_review_screenshot(iap_id: str) -> None:
    response = SESSION.get(f"{BASE_URL}/inAppPurchases/{iap_id}/relationships/appStoreReviewScreenshot", timeout=60)
    if response.status_code == 404:
        return
    if response.status_code >= 400:
        print(response.text)
        response.raise_for_status()
    data = response.json().get("data")
    if data and data.get("id"):
        delete(f"/inAppPurchaseAppStoreReviewScreenshots/{data['id']}")
        print(f"Deleted existing review screenshot {data['id']}.")


def upload_iap_image(iap_id: str, path: Path) -> str:
    payload = request(
        "POST",
        "/inAppPurchaseImages",
        {
            "data": {
                "type": "inAppPurchaseImages",
                "attributes": {"fileSize": path.stat().st_size, "fileName": path.name},
                "relationships": {
                    "inAppPurchase": {
                        "data": {"type": "inAppPurchases", "id": iap_id}
                    }
                },
            }
        },
    )
    image_id = payload["data"]["id"]
    upload_reserved_asset("inAppPurchaseImages", image_id, payload["data"]["attributes"], path)
    return image_id


def upload_iap_review_screenshot(iap_id: str, path: Path) -> str:
    payload = request(
        "POST",
        "/inAppPurchaseAppStoreReviewScreenshots",
        {
            "data": {
                "type": "inAppPurchaseAppStoreReviewScreenshots",
                "attributes": {"fileSize": path.stat().st_size, "fileName": path.name},
                "relationships": {
                    "inAppPurchaseV2": {
                        "data": {"type": "inAppPurchases", "id": iap_id}
                    }
                },
            }
        },
    )
    screenshot_id = payload["data"]["id"]
    upload_reserved_asset(
        "inAppPurchaseAppStoreReviewScreenshots",
        screenshot_id,
        payload["data"]["attributes"],
        path,
    )
    return screenshot_id


def upload_subscription_assets() -> None:
    for product_id, paths in SUBSCRIPTION_ASSETS.items():
        iap_id = in_app_purchase_id(product_id)
        print(f"Uploading subscription assets for {product_id} ({iap_id}).")
        clear_iap_images(iap_id)
        upload_iap_image(iap_id, paths["promo"])
        clear_iap_review_screenshot(iap_id)
        upload_iap_review_screenshot(iap_id, paths["review"])


def main() -> None:
    localization_id = app_store_version_localization_id()
    upload_app_screenshot_sets(localization_id)
    upload_subscription_assets()
    print("App Store media upload completed.")


if __name__ == "__main__":
    main()
