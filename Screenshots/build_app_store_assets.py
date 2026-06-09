from __future__ import annotations

import math
import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "Screenshots" / "Premium"
OUT_ROOT = ROOT / "Screenshots" / "AppStore"
SHARED_DIR = OUT_ROOT / "Shared"
BACKGROUND = SHARED_DIR / "humanized-desk-background.png"

IPHONE_65 = (1242, 2688)
IPAD_13 = (2064, 2752)
IPAD_13_COMPAT = (2048, 2732)
PROMO_SQUARE = (1024, 1024)

COLORS = {
    "deep": (4, 10, 19),
    "navy": (8, 18, 32),
    "panel": (24, 29, 38),
    "panel2": (30, 35, 43),
    "gold": (215, 171, 77),
    "pale_gold": (245, 221, 147),
    "ivory": (242, 237, 222),
    "muted": (174, 181, 192),
    "teal": (77, 184, 196),
    "green": (86, 191, 145),
}


@dataclass(frozen=True)
class ScreenSpec:
    source: str
    slug: str
    title: str
    subtitle: str
    kicker: str
    story: tuple[str, str, str]
    chips: tuple[str, ...]


SCREENS = (
    ScreenSpec(
        "01-dashboard-family-office.png",
        "01-family-readiness-command-center",
        "A calmer family estate command center",
        "See readiness, records, and next steps in one secure view.",
        "Family office profile",
        ("Harper Family Estate", "6 assets recorded", "Legal review reminder ready"),
        ("88% ready", "6 assets", "3 beneficiaries"),
    ),
    ScreenSpec(
        "02-filled-legacy-profile.png",
        "02-humanized-legacy-profile",
        "Turn family context into a clear plan",
        "Dependents, ownership, and planning goals stay organized for review.",
        "Legacy profile",
        ("Olivia and James Harper", "Children, ownership, digital assets", "Roadmap generated"),
        ("Profile", "Dependents", "Goals"),
    ),
    ScreenSpec(
        "03-filled-asset-form.png",
        "03-complete-asset-inventory",
        "Record the details people will need",
        "Property, accounts, documents, and notes in one practical inventory.",
        "Asset inventory",
        ("Harper family home", "Property details captured", "Supporting documents noted"),
        ("GBP 1.9M", "6 assets", "Documents"),
    ),
    ScreenSpec(
        "04-filled-voice-legacy.png",
        "04-voice-legacy-recorded",
        "Preserve wishes in your own voice",
        "Capture transcripts, family notes, and executor context.",
        "Voice legacy",
        ("Personal wishes recorded", "Transcript and notes generated", "Secure placeholder storage"),
        ("Voice", "Transcript", "Notes"),
    ),
    ScreenSpec(
        "05-filled-vault-guardian-documents.png",
        "05-guardians-documents-vault",
        "Keep guardians and documents together",
        "Critical family instructions stay structured and reviewable.",
        "Secure vault",
        ("Guardian plan", "Document vault", "Final wishes checklist"),
        ("2 children", "5 accounts", "4 records"),
    ),
    ScreenSpec(
        "06-family-office-subscription.png",
        "06-premium-family-office-plans",
        "Premium planning when the family needs more",
        "Unlimited assets, AI reviews, reports, and shared placeholders.",
        "Subscriptions",
        ("Premium and Family Office", "Monthly and annual options", "Built for fuller family workflows"),
        ("Premium", "Yearly", "Family Office"),
    ),
    ScreenSpec(
        "07-estate-review-report.png",
        "07-estate-review-report-ready",
        "Export a review-ready estate snapshot",
        "Bring a clear summary to adviser and family check-ins.",
        "Estate review",
        ("88% readiness report", "Assets, beneficiaries, executors", "Export checklist complete"),
        ("PDF", "88%", "Review"),
    ),
)

SUBSCRIPTIONS = (
    {
        "id": "com.legacyvaultai.premium.monthly",
        "slug": "premium-monthly",
        "title": "Premium Monthly",
        "price": "GBP 9.99 / month",
        "plan_key": "premium-monthly",
        "subtitle": "Unlimited assets, voice legacy, readiness engine, reports, and AI assistant.",
        "features": ("Unlimited records", "Voice legacy", "PDF estate reviews", "AI recommendations"),
        "accent": COLORS["gold"],
    },
    {
        "id": "com.legacyvaultai.premium.yearly",
        "slug": "premium-yearly",
        "title": "Premium Yearly",
        "price": "Annual Premium",
        "plan_key": "premium-yearly",
        "subtitle": "A full-year planning workspace for organized family estate records.",
        "features": ("Annual continuity", "Unlimited records", "Exportable reports", "Voice transcripts"),
        "accent": COLORS["pale_gold"],
    },
    {
        "id": "com.legacyvaultai.familyoffice.monthly",
        "slug": "family-office-monthly",
        "title": "Family Office Monthly",
        "price": "GBP 24.99 / month",
        "plan_key": "family-office-monthly",
        "subtitle": "Advanced family legacy tools, shared placeholders, and richer reviews.",
        "features": ("Multiple family members", "Shared vault placeholders", "Advanced reports", "Premium legacy tools"),
        "accent": COLORS["green"],
    },
)


def font(size: int, weight: str = "regular", serif: bool = False) -> ImageFont.FreeTypeFont:
    font_dir = Path("C:/Windows/Fonts")
    candidates: list[str]
    if serif:
        candidates = ["georgiab.ttf", "Georgia.ttf", "timesbd.ttf"]
    elif weight == "bold":
        candidates = ["segouib.ttf", "segoeuib.ttf", "arialbd.ttf"]
    elif weight == "semibold":
        candidates = ["seguisb.ttf", "segouisb.ttf", "segoeuib.ttf", "arialbd.ttf"]
    else:
        candidates = ["segoeui.ttf", "arial.ttf"]

    for candidate in candidates:
        path = font_dir / candidate
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default(size=size)


def ensure_dirs() -> None:
    for path in (
        OUT_ROOT / "iPhone_6.5_1242x2688",
        OUT_ROOT / "iPad_13_2064x2752",
        OUT_ROOT / "iPad_13_2048x2732",
        OUT_ROOT / "Subscriptions" / "AppReviewScreenshots_1242x2688",
        OUT_ROOT / "Subscriptions" / "PromotionalImages_1024x1024",
        SHARED_DIR,
    ):
        path.mkdir(parents=True, exist_ok=True)


def copy_generated_background_if_needed() -> None:
    if BACKGROUND.exists():
        return
    generated_root = Path.home() / ".codex" / "generated_images"
    if generated_root.exists():
        candidates = sorted(
            generated_root.rglob("*.png"),
            key=lambda p: p.stat().st_mtime,
            reverse=True,
        )
        if candidates:
            shutil.copy2(candidates[0], BACKGROUND)
            return
    make_fallback_background().save(BACKGROUND, "PNG")


def make_fallback_background(size: tuple[int, int] = (1600, 2400)) -> Image.Image:
    width, height = size
    img = Image.new("RGB", size, COLORS["deep"])
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / max(1, height - 1)
        r = int(6 + 18 * t)
        g = int(12 + 17 * t)
        b = int(22 + 14 * t)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    for cx, cy, radius, color in (
        (width * 0.25, height * 0.22, width * 0.42, (55, 43, 28)),
        (width * 0.72, height * 0.18, width * 0.34, (20, 76, 78)),
        (width * 0.50, height * 0.80, width * 0.50, (21, 32, 52)),
    ):
        layer = Image.new("RGBA", size, (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        ld.ellipse(
            (cx - radius, cy - radius, cx + radius, cy + radius),
            fill=(*color, 90),
        )
        img = Image.alpha_composite(img.convert("RGBA"), layer.filter(ImageFilter.GaussianBlur(130))).convert("RGB")
    return img


def cover(src: Image.Image, size: tuple[int, int]) -> Image.Image:
    width, height = size
    scale = max(width / src.width, height / src.height)
    resized = src.resize((math.ceil(src.width * scale), math.ceil(src.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - width) // 2
    top = (resized.height - height) // 2
    return resized.crop((left, top, left + width, top + height))


def contain(src: Image.Image, size: tuple[int, int]) -> Image.Image:
    width, height = size
    scale = min(width / src.width, height / src.height)
    return src.resize((round(src.width * scale), round(src.height * scale)), Image.Resampling.LANCZOS)


def base_canvas(size: tuple[int, int]) -> Image.Image:
    bg = cover(Image.open(BACKGROUND).convert("RGB"), size).convert("RGBA")
    width, height = size
    overlay = Image.new("RGBA", size, (4, 10, 19, 168))
    bg = Image.alpha_composite(bg, overlay)

    grad = Image.new("RGBA", size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for y in range(height):
        t = y / max(1, height - 1)
        alpha = int(46 + 92 * t)
        gd.line([(0, y), (width, y)], fill=(0, 5, 14, alpha))
    bg = Image.alpha_composite(bg, grad)

    vignette = Image.new("L", size, 0)
    vd = ImageDraw.Draw(vignette)
    vd.ellipse((-width * 0.08, -height * 0.05, width * 1.08, height * 1.0), fill=255)
    vignette = Image.eval(vignette.filter(ImageFilter.GaussianBlur(width // 9)), lambda p: 105 - int(p * 0.34))
    bg = Image.alpha_composite(bg, Image.new("RGBA", size, (0, 0, 0, 0)))
    bg.putalpha(255)
    dark = Image.new("RGBA", size, (0, 0, 0, 0))
    dark.putalpha(vignette)
    return Image.alpha_composite(bg, dark).convert("RGBA")


def text_width(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.ImageFont) -> int:
    bbox = draw.textbbox((0, 0), text, font=fnt)
    return bbox[2] - bbox[0]


def wrap_lines(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.ImageFont, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        if current and text_width(draw, candidate, fnt) > max_width:
            lines.append(current)
            current = word
        else:
            current = candidate
    if current:
        lines.append(current)
    return lines


def draw_wrapped(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int],
    text: str,
    fnt: ImageFont.ImageFont,
    fill: tuple[int, int, int],
    max_width: int,
    spacing: int,
) -> int:
    x, y = xy
    for line in wrap_lines(draw, text, fnt, max_width):
        draw.text((x, y), line, font=fnt, fill=fill)
        bbox = draw.textbbox((x, y), line, font=fnt)
        y = bbox[3] + spacing
    return y


def round_shadow(
    canvas: Image.Image,
    box: tuple[int, int, int, int],
    radius: int,
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int] | None = None,
    width: int = 1,
    shadow_alpha: int = 110,
    blur: int = 34,
    offset: tuple[int, int] = (0, 18),
) -> None:
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    sx1, sy1, sx2, sy2 = box
    dx, dy = offset
    ld.rounded_rectangle((sx1 + dx, sy1 + dy, sx2 + dx, sy2 + dy), radius=radius, fill=(0, 0, 0, shadow_alpha))
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def paste_rounded(dst: Image.Image, src: Image.Image, xy: tuple[int, int], radius: int) -> None:
    mask = Image.new("L", src.size, 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, src.width, src.height), radius=radius, fill=255)
    dst.paste(src, xy, mask)


def clear_status_strip(screen: Image.Image) -> Image.Image:
    cleaned = screen.convert("RGB").copy()
    draw = ImageDraw.Draw(cleaned)
    strip_h = max(136, round(cleaned.height * 0.048))
    sample = cleaned.getpixel((cleaned.width // 2, min(strip_h + 12, cleaned.height - 1)))
    fill = tuple(max(0, channel - 8) for channel in sample)
    draw.rectangle((0, 0, cleaned.width, strip_h), fill=fill)
    return cleaned


def draw_chip(draw: ImageDraw.ImageDraw, x: int, y: int, text: str, scale: float = 1.0) -> int:
    fnt = font(round(24 * scale), "semibold")
    pad_x = round(17 * scale)
    pad_y = round(9 * scale)
    tw = text_width(draw, text, fnt)
    h = round(44 * scale)
    box = (x, y, x + tw + pad_x * 2, y + h)
    draw.rounded_rectangle(box, radius=round(19 * scale), fill=(215, 171, 77, 215))
    draw.text((x + pad_x, y + pad_y), text, font=fnt, fill=COLORS["deep"])
    return box[2]


def draw_header(
    canvas: Image.Image,
    title: str,
    subtitle: str,
    kicker: str,
    margin: int,
    max_width: int,
    scale: float,
) -> int:
    draw = ImageDraw.Draw(canvas)
    y = margin
    draw.text((margin, y), "LegacyVault AI", font=font(round(26 * scale), "bold"), fill=COLORS["pale_gold"])
    y += round(44 * scale)
    draw.text((margin, y), kicker.upper(), font=font(round(20 * scale), "semibold"), fill=(150, 193, 197))
    y += round(46 * scale)
    y = draw_wrapped(
        draw,
        (margin, y),
        title,
        font(round(59 * scale), "bold", serif=True),
        COLORS["ivory"],
        max_width,
        round(11 * scale),
    )
    y += round(10 * scale)
    y = draw_wrapped(
        draw,
        (margin, y),
        subtitle,
        font(round(29 * scale)),
        COLORS["muted"],
        max_width,
        round(8 * scale),
    )
    return y


def draw_phone_frame(
    canvas: Image.Image,
    screen: Image.Image,
    center_x: int,
    top: int,
    max_w: int,
    max_h: int,
    scale: float,
) -> tuple[int, int, int, int]:
    screen = clear_status_strip(screen)
    inner = contain(screen, (max_w - round(54 * scale), max_h - round(60 * scale)))
    outer_w = inner.width + round(44 * scale)
    outer_h = inner.height + round(48 * scale)
    x = center_x - outer_w // 2
    y = top
    round_shadow(
        canvas,
        (x, y, x + outer_w, y + outer_h),
        radius=round(68 * scale),
        fill=(3, 7, 12, 255),
        outline=(242, 207, 119, 90),
        width=max(2, round(2 * scale)),
        shadow_alpha=135,
        blur=round(38 * scale),
        offset=(0, round(22 * scale)),
    )
    sx = x + round(22 * scale)
    sy = y + round(24 * scale)
    paste_rounded(canvas, inner, (sx, sy), radius=round(48 * scale))
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((sx, sy, sx + inner.width, sy + inner.height), radius=round(48 * scale), outline=(215, 171, 77, 90), width=max(2, round(2 * scale)))
    return x, y, x + outer_w, y + outer_h


def draw_story_panel(
    canvas: Image.Image,
    box: tuple[int, int, int, int],
    spec: ScreenSpec,
    scale: float,
) -> None:
    x1, y1, x2, y2 = box
    round_shadow(
        canvas,
        box,
        radius=round(26 * scale),
        fill=(20, 25, 34, 226),
        outline=(215, 171, 77, 100),
        width=max(1, round(2 * scale)),
        shadow_alpha=75,
        blur=round(22 * scale),
        offset=(0, round(12 * scale)),
    )
    draw = ImageDraw.Draw(canvas)
    x = x1 + round(28 * scale)
    y = y1 + round(26 * scale)
    draw.text((x, y), spec.story[0], font=font(round(33 * scale), "bold"), fill=COLORS["ivory"])
    y += round(55 * scale)
    for line in spec.story[1:]:
        y = draw_wrapped(draw, (x, y), line, font(round(23 * scale)), COLORS["muted"], x2 - x - round(26 * scale), round(7 * scale))
        y += round(8 * scale)
    cy = y2 - round(62 * scale)
    cx = x
    for chip in spec.chips[:3]:
        nx = draw_chip(draw, cx, cy, chip, scale=0.78 * scale)
        cx = nx + round(12 * scale)


def make_iphone_asset(spec: ScreenSpec) -> Image.Image:
    size = IPHONE_65
    width, height = size
    canvas = base_canvas(size)
    scale = width / 1242
    margin = round(74 * scale)
    header_bottom = draw_header(canvas, spec.title, spec.subtitle, spec.kicker, margin, width - margin * 2, scale)
    draw = ImageDraw.Draw(canvas)
    cx = margin
    chip_y = min(header_bottom + round(20 * scale), round(505 * scale))
    for chip in spec.chips[:3]:
        nx = draw_chip(draw, cx, chip_y, chip, scale=0.92 * scale)
        cx = nx + round(14 * scale)

    screen = clear_status_strip(Image.open(SOURCE_DIR / spec.source).convert("RGB"))
    phone_top = round(690 * scale)
    max_h = height - phone_top - round(56 * scale)
    draw_phone_frame(canvas, screen, width // 2, phone_top, round(982 * scale), max_h, scale)
    return canvas.convert("RGB")


def draw_ipad_workspace(canvas: Image.Image, spec: ScreenSpec, target: tuple[int, int]) -> None:
    width, height = target
    scale = width / 2048
    draw = ImageDraw.Draw(canvas)
    panel = (round(86 * scale), round(620 * scale), width - round(86 * scale), height - round(86 * scale))
    round_shadow(
        canvas,
        panel,
        radius=round(34 * scale),
        fill=(8, 15, 27, 238),
        outline=(215, 171, 77, 102),
        width=max(2, round(2 * scale)),
        shadow_alpha=115,
        blur=round(34 * scale),
        offset=(0, round(20 * scale)),
    )
    x1, y1, x2, y2 = panel
    inner_margin = round(58 * scale)
    draw.text((x1 + inner_margin, y1 + round(44 * scale)), "LegacyVault AI", font=font(round(25 * scale), "bold"), fill=COLORS["pale_gold"])

    screen = Image.open(SOURCE_DIR / spec.source).convert("RGB")
    screenshot_w = round(690 * scale)
    screenshot_h = y2 - y1 - round(238 * scale)
    screenshot = contain(screen, (screenshot_w, screenshot_h))
    phone_x = x1 + inner_margin
    phone_y = y1 + round(104 * scale)
    round_shadow(
        canvas,
        (
            phone_x - round(18 * scale),
            phone_y - round(20 * scale),
            phone_x + screenshot.width + round(18 * scale),
            phone_y + screenshot.height + round(20 * scale),
        ),
        radius=round(48 * scale),
        fill=(3, 7, 12, 255),
        outline=(215, 171, 77, 90),
        width=max(2, round(2 * scale)),
        shadow_alpha=105,
        blur=round(28 * scale),
        offset=(0, round(16 * scale)),
    )
    paste_rounded(canvas, screenshot, (phone_x, phone_y), round(38 * scale))

    right_x = phone_x + screenshot.width + round(88 * scale)
    right_w = x2 - right_x - inner_margin
    y = y1 + round(124 * scale)
    draw.text((right_x, y), spec.story[0], font=font(round(54 * scale), "bold", serif=True), fill=COLORS["ivory"])
    y += round(84 * scale)
    y = draw_wrapped(draw, (right_x, y), spec.subtitle, font(round(31 * scale)), COLORS["muted"], right_w, round(10 * scale))
    y += round(36 * scale)

    card_h = round(210 * scale)
    for idx, line in enumerate(spec.story[1:]):
        card = (right_x, y, right_x + right_w, y + card_h)
        fill = (24, 29, 38, 230) if idx == 0 else (19, 31, 42, 226)
        round_shadow(
            canvas,
            card,
            radius=round(22 * scale),
            fill=fill,
            outline=(215, 171, 77, 86),
            width=max(1, round(2 * scale)),
            shadow_alpha=50,
            blur=round(18 * scale),
            offset=(0, round(10 * scale)),
        )
        icon_x = right_x + round(34 * scale)
        icon_y = y + round(46 * scale)
        draw.ellipse((icon_x, icon_y, icon_x + round(62 * scale), icon_y + round(62 * scale)), fill=COLORS["gold"] if idx == 0 else COLORS["teal"])
        draw.text((icon_x + round(18 * scale), icon_y + round(7 * scale)), str(idx + 1), font=font(round(34 * scale), "bold"), fill=COLORS["deep"])
        draw_wrapped(
            draw,
            (right_x + round(112 * scale), y + round(43 * scale)),
            line,
            font(round(30 * scale), "semibold"),
            COLORS["ivory"],
            right_w - round(150 * scale),
            round(9 * scale),
        )
        y += card_h + round(28 * scale)

    metric_y = min(y + round(14 * scale), y2 - round(395 * scale))
    metric_w = (right_w - round(34 * scale)) // 3
    for i, chip in enumerate(spec.chips[:3]):
        mx = right_x + i * (metric_w + round(17 * scale))
        card = (mx, metric_y, mx + metric_w, metric_y + round(156 * scale))
        draw.rounded_rectangle(card, radius=round(18 * scale), fill=(30, 35, 43, 235), outline=(215, 171, 77, 80), width=max(1, round(2 * scale)))
        draw.text((mx + round(24 * scale), metric_y + round(30 * scale)), chip, font=font(round(30 * scale), "bold"), fill=COLORS["pale_gold"])
        draw.text((mx + round(24 * scale), metric_y + round(84 * scale)), "captured", font=font(round(20 * scale)), fill=COLORS["muted"])

    handoff_y = metric_y + round(205 * scale)
    handoff_h = max(round(330 * scale), y2 - handoff_y - round(294 * scale))
    handoff = (right_x, handoff_y, right_x + right_w, handoff_y + handoff_h)
    round_shadow(
        canvas,
        handoff,
        radius=round(22 * scale),
        fill=(18, 24, 33, 232),
        outline=(77, 184, 196, 92),
        width=max(1, round(2 * scale)),
        shadow_alpha=42,
        blur=round(18 * scale),
        offset=(0, round(10 * scale)),
    )
    hx = right_x + round(34 * scale)
    hy = handoff_y + round(32 * scale)
    draw.text((hx, hy), "Designed for family handoffs", font=font(round(32 * scale), "bold"), fill=COLORS["ivory"])
    hy += round(62 * scale)
    handoff_rows = (
        ("Private estate records stay organized", COLORS["gold"]),
        ("Human context travels with documents", COLORS["teal"]),
        ("Reports support adviser conversations", COLORS["green"]),
    )
    for row, color in handoff_rows:
        draw.ellipse((hx, hy + round(7 * scale), hx + round(28 * scale), hy + round(35 * scale)), fill=color)
        draw.text((hx + round(48 * scale), hy), row, font=font(round(25 * scale), "semibold"), fill=COLORS["muted"])
        hy += round(55 * scale)
    bar_x = hx
    bar_y = hy + round(18 * scale)
    for idx, value in enumerate((0.86, 0.74, 0.92)):
        ybar = bar_y + idx * round(42 * scale)
        draw.rounded_rectangle((bar_x, ybar, bar_x + right_w - round(72 * scale), ybar + round(16 * scale)), radius=round(8 * scale), fill=(76, 85, 100))
        draw.rounded_rectangle((bar_x, ybar, bar_x + round((right_w - 72 * scale) * value), ybar + round(16 * scale)), radius=round(8 * scale), fill=handoff_rows[idx][1])

    disclaimer = "Educational organization only. Professional legal review is recommended."
    draw_wrapped(
        draw,
        (right_x, y2 - round(190 * scale)),
        disclaimer,
        font(round(23 * scale), "semibold"),
        COLORS["pale_gold"],
        right_w,
        round(8 * scale),
    )


def make_ipad_asset(spec: ScreenSpec, target: tuple[int, int]) -> Image.Image:
    width, _ = target
    canvas = base_canvas(target)
    scale = width / 2048
    margin = round(94 * scale)
    draw_header(canvas, spec.title, spec.subtitle, spec.kicker, margin, width - margin * 2, scale * 1.02)
    draw_ipad_workspace(canvas, spec, target)
    return canvas.convert("RGB")


def app_screen_background(size: tuple[int, int]) -> Image.Image:
    width, height = size
    img = Image.new("RGBA", size, COLORS["deep"])
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / max(1, height - 1)
        r = int(4 + 10 * t)
        g = int(10 + 15 * t)
        b = int(19 + 23 * t)
        draw.line((0, y, width, y), fill=(r, g, b, 255))
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((-220, 140, 760, 1260), fill=(28, 76, 75, 82))
    gd.ellipse((520, 220, 1500, 1100), fill=(70, 50, 30, 54))
    return Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(120)))


def draw_plan_card(
    canvas: Image.Image,
    box: tuple[int, int, int, int],
    title: str,
    price: str,
    description: str,
    features: tuple[str, ...],
    selected: bool,
    accent: tuple[int, int, int],
    product_id: str | None = None,
) -> None:
    draw = ImageDraw.Draw(canvas)
    fill = (39, 32, 18, 245) if selected else (24, 29, 38, 238)
    outline = (*accent, 210 if selected else 120)
    draw.rounded_rectangle(box, radius=24, fill=fill, outline=outline, width=3 if selected else 2)
    x1, y1, x2, _ = box
    x = x1 + 30
    y = y1 + 26
    draw.text((x, y), title, font=font(38, "bold"), fill=COLORS["ivory"])
    draw.text((x, y + 56), price, font=font(28, "semibold"), fill=accent)
    if selected:
        badge = "Selected for App Review"
    else:
        badge = "Available"
    badge_font = font(21, "bold")
    badge_w = text_width(draw, badge, badge_font) + 36
    draw.rounded_rectangle((x2 - badge_w - 28, y + 6, x2 - 28, y + 46), radius=20, fill=(*accent, 235) if selected else (88, 96, 110, 230))
    draw.text((x2 - badge_w - 10, y + 13), badge, font=badge_font, fill=COLORS["deep"] if selected else COLORS["ivory"])
    y += 104
    y = draw_wrapped(draw, (x, y), description, font(24), COLORS["muted"], x2 - x - 34, 7)
    y += 15
    for feature in features[:3]:
        draw.ellipse((x, y + 8, x + 18, y + 26), fill=accent)
        draw.text((x + 34, y), feature, font=font(22, "semibold"), fill=COLORS["ivory"] if selected else COLORS["muted"])
        y += 36
    if product_id:
        draw.text((x, box[3] - 42), product_id, font=font(18, "semibold"), fill=COLORS["pale_gold"])


def make_subscription_app_screen(sub: dict[str, object]) -> Image.Image:
    width, height = (1290, 2796)
    canvas = app_screen_background((width, height))
    draw = ImageDraw.Draw(canvas)
    accent = sub["accent"]
    selected_key = str(sub["plan_key"])

    y = 88
    draw.text((72, y), "LegacyVault AI", font=font(31, "bold"), fill=COLORS["pale_gold"])
    y += 72
    draw.text((72, y), "LegacyVault AI Plans", font=font(58, "bold", serif=True), fill=COLORS["ivory"])
    y += 80
    y = draw_wrapped(
        draw,
        (72, y),
        "Premium estate organization, voice legacy recordings, reports, and AI insights.",
        font(29),
        COLORS["muted"],
        width - 144,
        9,
    )
    y += 38
    current = f"Reviewing: {sub['title']}"
    draw.rounded_rectangle((72, y, width - 72, y + 86), radius=24, fill=(23, 29, 38, 236), outline=(*accent, 142), width=2)
    draw.text((104, y + 25), current, font=font(27, "bold"), fill=COLORS["ivory"])
    y += 122

    plan_defs = (
        (
            "free",
            "Free",
            "GBP 0",
            "Basic checklist, limited assets, and limited vault storage.",
            ("Basic checklist", "Limited records", "Starter organization"),
            COLORS["muted"],
            None,
        ),
        (
            "premium-monthly",
            "Premium Monthly",
            "GBP 9.99 / month",
            "Unlimited organization and premium planning tools.",
            ("Unlimited assets", "Voice legacy recordings", "PDF reports"),
            COLORS["gold"],
            "com.legacyvaultai.premium.monthly",
        ),
        (
            "premium-yearly",
            "Premium Yearly",
            "Annual Premium",
            "A full-year planning workspace for family continuity.",
            ("Annual continuity", "Unlimited records", "AI recommendations"),
            COLORS["pale_gold"],
            "com.legacyvaultai.premium.yearly",
        ),
        (
            "family-office-monthly",
            "Family Office Monthly",
            "GBP 24.99 / month",
            "Advanced tools for fuller family legacy workflows.",
            ("Multiple family members", "Shared vault placeholders", "Advanced reports"),
            COLORS["green"],
            "com.legacyvaultai.familyoffice.monthly",
        ),
    )
    card_h = 342
    for key, title, price, desc, features, plan_accent, product_id in plan_defs:
        draw_plan_card(
            canvas,
            (72, y, width - 72, y + card_h),
            title,
            price,
            desc,
            features,
            selected=key == selected_key,
            accent=plan_accent if key == selected_key else COLORS["gold"],
            product_id=product_id if key == selected_key else None,
        )
        y += card_h + 34

    legal = (72, height - 260, width - 72, height - 150)
    draw.rounded_rectangle(legal, radius=22, fill=(24, 29, 38, 240), outline=(215, 171, 77, 122), width=2)
    draw.text((104, height - 228), "Educational only - not legal advice", font=font(24, "bold"), fill=COLORS["pale_gold"])
    draw_wrapped(draw, (104, height - 190), "Jurisdiction-specific laws vary. Qualified legal review is recommended.", font(20), COLORS["muted"], width - 208, 6)

    nav = (58, height - 118, width - 58, height - 36)
    draw.rounded_rectangle(nav, radius=34, fill=(20, 25, 34, 244), outline=(215, 171, 77, 120), width=2)
    for idx, label in enumerate(("Dashboard", "Assets", "Vault", "Voice", "Settings")):
        cx = 150 + idx * 248
        draw.ellipse((cx - 16, height - 96, cx + 16, height - 64), fill=COLORS["gold"] if idx == 4 else (88, 96, 110))
        draw.text((cx - 43, height - 55), label, font=font(17), fill=COLORS["pale_gold"] if idx == 4 else COLORS["muted"])
    return canvas.convert("RGB")


def make_subscription_review(sub: dict[str, object]) -> Image.Image:
    width, height = IPHONE_65
    canvas = base_canvas(IPHONE_65)
    scale = width / 1242
    margin = round(74 * scale)
    draw_header(
        canvas,
        str(sub["title"]),
        str(sub["subtitle"]),
        "Subscription review screenshot",
        margin,
        width - margin * 2,
        scale,
    )
    draw = ImageDraw.Draw(canvas)
    y = round(505 * scale)
    draw_chip(draw, margin, y, str(sub["id"]), scale=0.78 * scale)
    screen = make_subscription_app_screen(sub)
    draw_phone_frame(canvas, screen, width // 2, round(710 * scale), round(982 * scale), height - round(770 * scale), scale)

    callout_w = round(880 * scale)
    callout_h = round(174 * scale)
    callout = (
        (width - callout_w) // 2,
        height - round(250 * scale),
        (width + callout_w) // 2,
        height - round(250 * scale) + callout_h,
    )
    round_shadow(
        canvas,
        callout,
        radius=round(22 * scale),
        fill=(20, 25, 34, 238),
        outline=(*sub["accent"], 135),
        width=max(2, round(2 * scale)),
        shadow_alpha=80,
        blur=round(22 * scale),
        offset=(0, round(10 * scale)),
    )
    x = callout[0] + round(30 * scale)
    cy = callout[1] + round(28 * scale)
    draw.text((x, cy), str(sub["title"]), font=font(round(33 * scale), "bold"), fill=COLORS["ivory"])
    draw.text((x, cy + round(52 * scale)), str(sub["price"]), font=font(round(28 * scale), "semibold"), fill=sub["accent"])
    draw_wrapped(draw, (x, cy + round(94 * scale)), "Shown in app paywall for App Review.", font(round(21 * scale)), COLORS["muted"], callout_w - round(60 * scale), round(6 * scale))
    return canvas.convert("RGB")


def make_promo_square(sub: dict[str, object]) -> Image.Image:
    size = PROMO_SQUARE
    canvas = base_canvas(size)
    draw = ImageDraw.Draw(canvas)
    scale = size[0] / 1024
    accent = sub["accent"]

    round_shadow(
        canvas,
        (64, 70, 960, 940),
        radius=34,
        fill=(12, 20, 32, 232),
        outline=(*accent, 120),
        width=2,
        shadow_alpha=110,
        blur=34,
        offset=(0, 18),
    )
    draw.text((112, 116), "LegacyVault AI", font=font(34, "bold"), fill=COLORS["pale_gold"])
    y = draw_wrapped(draw, (112, 184), str(sub["title"]), font(74, "bold", serif=True), COLORS["ivory"], 760, 12)
    y += 14
    draw.text((112, y), str(sub["price"]), font=font(48, "semibold"), fill=accent)
    y += 72
    y = draw_wrapped(draw, (112, y), str(sub["subtitle"]), font(33), COLORS["muted"], 770, 12)

    icon_box = (704, 624, 884, 804)
    draw.ellipse(icon_box, fill=(*accent, 255))
    draw.text((754, 659), "LV", font=font(54, "bold", serif=True), fill=COLORS["deep"])
    draw.arc((668, 588, 920, 840), 215, 515, fill=COLORS["pale_gold"], width=9)

    y = max(y + 34, 520)
    for feature in tuple(sub["features"])[:3]:
        draw.ellipse((118, y + 12, 148, y + 42), fill=accent)
        draw.text((168, y), str(feature), font=font(34, "semibold"), fill=COLORS["ivory"])
        y += 66

    footer = "Educational organization only. Not legal advice."
    draw.rounded_rectangle((112, 838, 886, 892), radius=18, fill=(24, 29, 38, 232), outline=(215, 171, 77, 82), width=1)
    draw.text((138, 852), footer, font=font(23, "semibold"), fill=COLORS["pale_gold"])
    return canvas.convert("RGB")


def save_rgb(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(path, "PNG", dpi=(72, 72), optimize=True)


def make_contact_sheet(paths: list[Path], out_path: Path, thumb_size: tuple[int, int], columns: int = 4) -> None:
    label_h = 58
    rows = math.ceil(len(paths) / columns)
    sheet_w = columns * thumb_size[0] + (columns + 1) * 28
    sheet_h = rows * (thumb_size[1] + label_h) + (rows + 1) * 28
    sheet = Image.new("RGB", (sheet_w, sheet_h), (8, 12, 20))
    draw = ImageDraw.Draw(sheet)
    for idx, path in enumerate(paths):
        row = idx // columns
        col = idx % columns
        x = 28 + col * (thumb_size[0] + 28)
        y = 28 + row * (thumb_size[1] + label_h + 28)
        thumb = contain(Image.open(path).convert("RGB"), thumb_size)
        bg = Image.new("RGB", thumb_size, (18, 22, 30))
        bg.paste(thumb, ((thumb_size[0] - thumb.width) // 2, (thumb_size[1] - thumb.height) // 2))
        sheet.paste(bg, (x, y))
        draw.text((x, y + thumb_size[1] + 10), path.stem[:24], font=font(16), fill=COLORS["ivory"])
    save_rgb(sheet, out_path)


def build() -> None:
    ensure_dirs()
    copy_generated_background_if_needed()

    iphone_paths: list[Path] = []
    ipad_paths: list[Path] = []
    ipad_compat_paths: list[Path] = []
    for spec in SCREENS:
        iphone_path = OUT_ROOT / "iPhone_6.5_1242x2688" / f"{spec.slug}.png"
        ipad_path = OUT_ROOT / "iPad_13_2064x2752" / f"{spec.slug}.png"
        ipad_compat_path = OUT_ROOT / "iPad_13_2048x2732" / f"{spec.slug}.png"
        save_rgb(make_iphone_asset(spec), iphone_path)
        save_rgb(make_ipad_asset(spec, IPAD_13), ipad_path)
        save_rgb(make_ipad_asset(spec, IPAD_13_COMPAT), ipad_compat_path)
        iphone_paths.append(iphone_path)
        ipad_paths.append(ipad_path)
        ipad_compat_paths.append(ipad_compat_path)

    review_paths: list[Path] = []
    promo_paths: list[Path] = []
    for sub in SUBSCRIPTIONS:
        review_path = OUT_ROOT / "Subscriptions" / "AppReviewScreenshots_1242x2688" / f"{sub['slug']}-review-screenshot.png"
        promo_path = OUT_ROOT / "Subscriptions" / "PromotionalImages_1024x1024" / f"{sub['slug']}-promotional-image.png"
        save_rgb(make_subscription_review(sub), review_path)
        save_rgb(make_promo_square(sub), promo_path)
        review_paths.append(review_path)
        promo_paths.append(promo_path)

    make_contact_sheet(iphone_paths, OUT_ROOT / "iPhone_6.5_1242x2688" / "contact-sheet.png", (260, 562), columns=4)
    make_contact_sheet(ipad_paths, OUT_ROOT / "iPad_13_2064x2752" / "contact-sheet.png", (300, 400), columns=4)
    make_contact_sheet(ipad_compat_paths, OUT_ROOT / "iPad_13_2048x2732" / "contact-sheet.png", (300, 400), columns=4)
    make_contact_sheet(review_paths + promo_paths, OUT_ROOT / "Subscriptions" / "contact-sheet.png", (250, 540), columns=3)

    manifest = OUT_ROOT / "manifest.txt"
    manifest.write_text(
        "\n".join(
            [
                "LegacyVault AI App Store screenshot package",
                "",
                "iPhone 6.5-inch screenshots: Screenshots/AppStore/iPhone_6.5_1242x2688",
                "iPad 13-inch screenshots: Screenshots/AppStore/iPad_13_2064x2752",
                "iPad 13-inch compatible alternate: Screenshots/AppStore/iPad_13_2048x2732",
                "Subscription App Review screenshots: Screenshots/AppStore/Subscriptions/AppReviewScreenshots_1242x2688",
                "Subscription promotional images: Screenshots/AppStore/Subscriptions/PromotionalImages_1024x1024",
                "Artificial status bar text removed from composed screenshots.",
                "",
                "StoreKit products covered:",
                *[f"- {sub['id']}: {sub['title']}" for sub in SUBSCRIPTIONS],
            ]
        ),
        encoding="utf-8",
    )


if __name__ == "__main__":
    build()
