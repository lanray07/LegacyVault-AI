import Combine
import Foundation
import LocalAuthentication

struct BiometricAuthService {
    func biometricType() -> String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Device Authentication"
        }
    }

    func authenticate(reason: String) async -> Bool {
        await withCheckedContinuation { continuation in
            let context = LAContext()
            var error: NSError?
            let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics

            guard context.canEvaluatePolicy(policy, error: &error) else {
                continuation.resume(returning: false)
                return
            }

            context.evaluatePolicy(policy, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}

@MainActor
final class SecurityViewModel: ObservableObject {
    @Published var isUnlocked = true
    @Published var biometricsEnabled = false
    @Published var statusMessage = "Vault unlocked for mock development."

    private let biometricService = BiometricAuthService()

    var biometricLabel: String {
        biometricService.biometricType()
    }

    func enableBiometrics() async {
        let success = await biometricService.authenticate(reason: "Protect your LegacyVault AI records.")
        biometricsEnabled = success
        isUnlocked = success
        statusMessage = success ? "\(biometricLabel) enabled." : "Biometric authentication was not enabled."
    }

    func lock() {
        guard biometricsEnabled else { return }
        isUnlocked = false
        statusMessage = "Vault locked."
    }

    func unlock() async {
        let success = await biometricService.authenticate(reason: "Unlock LegacyVault AI.")
        isUnlocked = success
        statusMessage = success ? "Vault unlocked." : "Unable to unlock vault."
    }
}

struct SecureVaultService {
    func encryptPlaceholder(_ value: String) -> String {
        Data(value.utf8).base64EncodedString()
    }

    func decryptPlaceholder(_ value: String) -> String {
        guard let data = Data(base64Encoded: value), let decoded = String(data: data, encoding: .utf8) else {
            return value
        }
        return decoded
    }

    var architectureSummary: String {
        "Secure vault placeholder for Keychain-backed metadata, file protection, encrypted document storage, and biometric unlock."
    }
}
