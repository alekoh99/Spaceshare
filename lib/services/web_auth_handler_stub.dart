import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart';

/// Stub implementation used on non-web platforms so the rest of the
/// codebase can import `web_auth_handler.dart` without pulling in
/// `dart:js` (which is web-only).
class WebAuthHandler {
  static void configureCOOPHeaders() {
    // No-op on non-web platforms.
    AppLogger.debug(
      'AUTH',
      'configureCOOPHeaders called on non-web platform. No-op.',
    );
  }

  static String getPopupDiagnostics() {
    return 'Popup diagnostics are only available on web platforms.';
  }
}

class EnhancedWebAuthProvider {
  final FirebaseAuth _auth;

  EnhancedWebAuthProvider(this._auth);

  /// On non-web platforms the web popup flow is not used. If this
  /// somehow gets called, fail with a clear error so it is easy to
  /// diagnose.
  Future<UserCredential?> signInWithGooglePopup(
    GoogleAuthProvider provider,
  ) async {
    AppLogger.error(
      'AUTH',
      'signInWithGooglePopup was called on a non-web platform.',
      null,
    );
    throw AuthException(
      'Google popup sign-in is only supported on web platforms.',
    );
  }
}


