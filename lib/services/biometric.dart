import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Thin wrapper around device biometrics (Face ID / Touch ID / fingerprint).
///
/// Designed to never hard-block the demo: if biometrics aren't available
/// (e.g. a simulator with nothing enrolled) it resolves as success so the
/// "unlock" flow still works. On a real device with Face ID set up, it
/// prompts for real.
abstract final class Biometric {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// True if the device can prompt for biometrics or a device passcode.
  static Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompt to unlock. Returns true on success (or when unavailable).
  static Future<bool> authenticate(
      {String reason = 'Unlock BirdCherry'}) async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported && !canCheck) return true; // nothing to prompt with
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow device passcode as a fallback
        ),
      );
    } catch (e) {
      debugPrint('Biometric.authenticate: $e');
      return true; // never trap the user out of a demo
    }
  }
}
