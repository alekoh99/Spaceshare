import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import '../utils/logger.dart';
import '../utils/exceptions.dart';

class WebAuthHandler {
  static void configureCOOPHeaders() {
    if (!kIsWeb) return;

    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          var originalOpen = window.open;
          window._openAuthPopup = function(url, target, features) {
            var defaultFeatures = 'width=500,height=600,left=100,top=100,scrollbars=yes,resizable=yes';
            var finalFeatures = features || defaultFeatures;
            
            try {
              var popup = originalOpen(url, target, finalFeatures);
              if (popup) popup.focus();
              return popup;
            } catch (e) {
              console.error('Popup open error:', e);
              return null;
            }
          };
        })()
        '''
      ]);

      AppLogger.debug('AUTH', 'COOP headers configured');
    } catch (e) {
      AppLogger.warning('AUTH', 'COOP configuration failed: $e');
    }
  }

  static String getPopupDiagnostics() {
    final buffer = StringBuffer();
    buffer.writeln('=== Popup Diagnostics ===');

    try {
      if (kIsWeb) {
        buffer.writeln('Platform: Web');
        buffer.writeln('Popup API Available: ${js.context["window"] != null}');

        final testPopup = js.context.callMethod(
          'open',
          ['about:blank', '_blank', 'width=100,height=100'],
        );
        if (testPopup == null) {
          buffer.writeln('Popup Blocker: Detected');
        } else {
          buffer.writeln('Popup Blocker: Not detected');
          testPopup.callMethod('close', []);
        }
      }
    } catch (e) {
      buffer.writeln('Diagnostics Error: $e');
    }

    return buffer.toString();
  }
}

class EnhancedWebAuthProvider {
  final FirebaseAuth _auth;

  EnhancedWebAuthProvider(this._auth);

  Future<UserCredential?> signInWithGooglePopup(
    GoogleAuthProvider provider,
  ) async {
    try {
      AppLogger.info('AUTH', 'Starting Google popup sign-in');
      WebAuthHandler.configureCOOPHeaders();

      provider.setCustomParameters({
        'prompt': 'select_account',
      });

      UserCredential? userCredential;
      int retryCount = 0;
      const int maxRetries = 2;

      while (userCredential == null && retryCount <= maxRetries) {
        try {
          AppLogger.debug(
            'AUTH',
            'Popup attempt ${retryCount + 1}/$maxRetries',
          );
          userCredential = await _auth.signInWithPopup(provider);
          AppLogger.success('AUTH', 'Popup sign-in successful');
          break;
        } on FirebaseAuthException catch (e) {
          final shouldRetry =
              (e.code == 'popup-closed-by-user' || e.code == 'popup-blocked') &&
                  retryCount < maxRetries;

          if (shouldRetry) {
            AppLogger.warning(
              'AUTH',
              'Popup issue (${e.code}), retrying...',
            );
            await Future.delayed(const Duration(milliseconds: 800));
            retryCount++;
          } else {
            AppLogger.warning('AUTH', 'Popup failed: ${e.code}');
            AppLogger.debug('AUTH', WebAuthHandler.getPopupDiagnostics());
            rethrow;
          }
        }
      }

      if (userCredential == null) {
        throw FirebaseAuthException(
          code: 'null-credential',
          message: 'Failed to obtain credentials from popup',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error(
        'AUTH',
        'Google popup sign-in failed: ${e.code}',
        e,
      );
      throw AuthException(
        'Google sign-in failed: ${_getErrorMessage(e.code)}',
      );
    } catch (e) {
      AppLogger.error('AUTH', 'Unexpected error in popup sign-in', e);
      throw AuthException('Failed to complete Google sign-in: $e');
    }
  }

  static String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'popup-closed-by-user':
        return 'Sign-in window was closed. Please try again.';
      case 'popup-blocked':
        return 'Popup was blocked by your browser. Please allow popups and try again.';
      case 'account-exists-with-different-credential':
        return 'This email is linked to a different sign-in method.';
      case 'invalid-credential':
        return 'Invalid sign-in credentials. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'Google sign-in is not available. Please contact support.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }
}


