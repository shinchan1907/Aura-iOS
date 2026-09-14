import Foundation
import LocalAuthentication
import SwiftUI

@Observable
public final class BiometricAuthManager {
    public static let shared = BiometricAuthManager()
    
    public var isBiometricsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBiometricsEnabled, forKey: "aura_is_biometrics_enabled")
        }
    }
    
    public var isLocked: Bool = false
    public var biometricType: LABiometryType = .none
    public var authError: String? = nil
    
    private init() {
        self.isBiometricsEnabled = UserDefaults.standard.bool(forKey: "aura_is_biometrics_enabled")
        checkBiometricSupport()
    }
    
    public func checkBiometricSupport() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            self.biometricType = context.biometryType
        } else {
            self.biometricType = .none
        }
    }
    
    public func lockIfNeeded() {
        if isBiometricsEnabled {
            self.isLocked = true
        }
    }
    
    public func authenticate(completion: ((Bool) -> Void)? = nil) {
        guard isBiometricsEnabled else {
            self.isLocked = false
            completion?(true)
            return
        }
        
        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"
        var error: NSError?
        
        // Allow Face ID / Touch ID or Passcode
        let policy: LAPolicy = .deviceOwnerAuthentication
        
        if context.canEvaluatePolicy(policy, error: &error) {
            let reason = "Unlock Aura to access your tasks and focus dashboard."
            context.evaluatePolicy(policy, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isLocked = false
                        self.authError = nil
                        completion?(true)
                    } else {
                        self.authError = authenticationError?.localizedDescription ?? "Authentication failed"
                        completion?(false)
                    }
                }
            }
        } else {
            // Biometrics / passcode not available on device
            DispatchQueue.main.async {
                self.isLocked = false
                completion?(true)
            }
        }
    }
}
