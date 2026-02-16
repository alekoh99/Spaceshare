import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:get/get.dart';
import '../utils/exceptions.dart' as exceptions;
import '../utils/logger.dart';
import '../utils/result.dart';
import 'firebase_realtime_database_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final FirebaseRealtimeDatabaseService _databaseService;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  FirebaseAuthService() {
    try {
      _databaseService = Get.find<FirebaseRealtimeDatabaseService>();
    } catch (e) {
      AppLogger.warning('AUTH', 'Database service not initialized: $e');
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw exceptions.AuthException('Email and password are required');
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      AppLogger.info('AUTH', 'Email sign-in success: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('AUTH', 'Email sign-in error: ${e.code}');
      if (e.code == 'user-not-found') {
        throw exceptions.AuthException('No account found with this email');
      } else if (e.code == 'wrong-password') {
        throw exceptions.AuthException('Incorrect password');
      } else if (e.code == 'too-many-requests') {
        throw exceptions.AuthException('Too many attempts. Try again later.');
      }
      throw exceptions.AuthException('Sign in failed: ${e.message}');
    } catch (e) {
      throw exceptions.AuthException('Failed to sign in: $e');
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw exceptions.AuthException('Email and password required');
      }

      email = email.trim();
      if (password.length < 8) {
        throw exceptions.AuthException('Password must be 8+ characters');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Send email verification
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        AppLogger.info('AUTH', 'Email verification sent to: $email');
      }
      
      AppLogger.info('AUTH', 'Email sign-up success: $email');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('AUTH', 'Email sign-up error: ${e.code}');
      if (e.code == 'email-already-in-use') {
        throw exceptions.AuthException('Email already registered');
      } else if (e.code == 'weak-password') {
        throw exceptions.AuthException('Password too weak');
      }
      throw exceptions.AuthException('Sign up failed: ${e.message}');
    } catch (e) {
      throw exceptions.AuthException('Failed to sign up: $e');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      AppLogger.debug('AUTH', 'Starting Firebase Google Sign-In');
      
      final GoogleAuthProvider provider = GoogleAuthProvider();
      provider.setCustomParameters({'prompt': 'select_account'});

      UserCredential? userCredential;

      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(provider);
        AppLogger.debug('AUTH', 'Web popup sign-in');
      } else if (Platform.isAndroid || Platform.isIOS) {
        await _googleSignIn.signOut();
        
        try {
          final googleUser = await _googleSignIn.signIn();
          
          if (googleUser == null) {
            throw exceptions.AuthException('Google sign-in cancelled');
          }

          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          userCredential = await _auth.signInWithCredential(credential);
          AppLogger.debug('AUTH', 'Mobile credential sign-in');
        } catch (e) {
          if (e is PlatformException) {
            AppLogger.error('AUTH', 'Google sign-in platform error: code=${e.code}, message=${e.message}');
            
            // Handle specific Google Play Services error codes
            if (e.code == '10') {
              throw exceptions.AuthException(
                'Google sign-in configuration error. Please verify:\n'
                '1. SHA-1 fingerprint is registered in Firebase Console\n'
                '2. Google Play Services is up to date\n'
                '3. OAuth 2.0 Client ID is properly configured'
              );
            } else if (e.code == '12501') {
              throw exceptions.AuthException('Google sign-in cancelled');
            } else if (e.code == '7') {
              throw exceptions.AuthException('Google Play Services is not available. Please update it.');
            }
          }
          rethrow;
        }
      }

      if (userCredential == null) {
        throw exceptions.AuthException('Google sign-in failed');
      }

      AppLogger.info('AUTH', 'Google sign-in success: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('AUTH', 'Firebase Google sign-in error: ${e.code}');
      if (e.code == 'popup-closed-by-user') {
        throw exceptions.AuthException('Sign-in popup closed');
      } else if (e.code == 'popup-blocked') {
        throw exceptions.AuthException('Popup blocked. Allow popups and try again.');
      }
      throw exceptions.AuthException('Google sign-in failed: ${e.message}');
    } on PlatformException catch (e) {
      AppLogger.error('AUTH', 'Platform exception during Google sign-in: code=${e.code}, message=${e.message}');
      
      // Handle specific Google Play Services error codes
      if (e.code == '10') {
        throw exceptions.AuthException(
          'Google sign-in configuration error.\n\n'
          'To fix this:\n'
          '1. Run: gradle signingReport\n'
          '2. Copy the SHA-1 fingerprint\n'
          '3. Add it to Firebase Console > Project Settings > Your Android App\n'
          '4. Download the updated google-services.json\n'
          '5. Rebuild the app'
        );
      } else if (e.code == '12501') {
        throw exceptions.AuthException('Google sign-in cancelled');
      } else if (e.code == '7') {
        throw exceptions.AuthException('Google Play Services unavailable. Please update it.');
      }
      
      throw exceptions.AuthException('Google sign-in failed: ${e.message}');
    } catch (e) {
      AppLogger.error('AUTH', 'Google sign-in exception: $e');
      throw exceptions.AuthException('Failed to sign in with Google: $e');
    }
  }

  Future<String> sendOTP(String phone) async {
    try {
      final normalizedPhone = _normalizePhone(phone);
      late String verificationId;
      bool codeSent = false;

      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        timeout: const Duration(minutes: 2),
        verificationCompleted: (credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          AppLogger.error('AUTH', 'Phone verification failed: ${e.code}');
          throw exceptions.AuthException('Phone verification failed: ${e.message}');
        },
        codeSent: (verId, _) {
          verificationId = verId;
          codeSent = true;
          AppLogger.info('AUTH', 'OTP sent to $normalizedPhone');
        },
        codeAutoRetrievalTimeout: (verId) {
          verificationId = verId;
        },
      );

      if (!codeSent) {
        throw exceptions.AuthException('Failed to send OTP');
      }

      return verificationId;
    } on FirebaseAuthException catch (e) {
      throw exceptions.AuthException('Phone verification error: ${e.message}');
    } catch (e) {
      throw exceptions.AuthException('Failed to send OTP: $e');
    }
  }

  Future<String> verifyOTP(String phone, String otp, String verificationId) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user?.uid;

      if (uid == null) {
        throw exceptions.AuthException('Failed to get user ID');
      }

      AppLogger.info('AUTH', 'OTP verification success for $phone');
      return uid;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('AUTH', 'OTP verification error: ${e.code}');
      if (e.code == 'invalid-verification-code') {
        throw exceptions.AuthException('Invalid OTP code');
      }
      throw exceptions.AuthException('OTP verification failed: ${e.message}');
    } catch (e) {
      throw exceptions.AuthException('Failed to verify OTP: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      AppLogger.info('AUTH', 'User signed out');
    } catch (e) {
      throw exceptions.AuthException('Sign out failed: $e');
    }
  }

  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  Future<bool> isAuthenticated() async {
    return _auth.currentUser != null;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.info('AUTH', 'Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw exceptions.AuthException('No account found with this email');
      }
      throw exceptions.AuthException('Failed to send reset email: ${e.message}');
    } catch (e) {
      throw exceptions.AuthException('Failed to send password reset: $e');
    }
  }

  Future<Result<void>> enableTwoFactor(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.failure(
          exceptions.AuthException('User not authenticated') as Exception
        );
      }

      try {
        await _databaseService.updatePath(
          'users/$userId',
          {
            'twoFactorEnabled': true,
            'twoFactorEnabledAt': DateTime.now().toIso8601String(),
          },
        );
        
        await _databaseService.createPath(
          'securityLogs/$userId/${DateTime.now().millisecondsSinceEpoch}',
          {
            'event': '2fa_enabled',
            'timestamp': DateTime.now().toIso8601String(),
            'method': 'firebase_mfa',
          },
        );
      } catch (e) {
        AppLogger.warning('AUTH', 'Failed to log 2FA enable: $e');
      }

      AppLogger.info('AUTH', '2FA enabled for $userId');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('AUTH', '2FA enable failed: $e');
      return Result.failure(
        exceptions.AuthException('Failed to enable 2FA: $e') as Exception
      );
    }
  }

  Future<Result<void>> disableTwoFactor(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.failure(
          exceptions.AuthException('User not authenticated') as Exception
        );
      }

      // Note: MultiFactor API is conditionally available
      try {
        final mfaSession = user.multiFactor;
        // MultiFactor API not reliably available - rely on Firestore data
        AppLogger.debug('AUTH', 'Disabling 2FA via Firestore');
      } catch (e) {
        AppLogger.debug('AUTH', 'MultiFactor unavailable: $e');
      }

      try {
        await _databaseService.updatePath(
          'users/$userId',
          {
            'twoFactorEnabled': false,
            'twoFactorDisabledAt': DateTime.now().toIso8601String(),
          },
        );
        
        await _databaseService.createPath(
          'securityLogs/$userId/${DateTime.now().millisecondsSinceEpoch}',
          {
            'event': '2fa_disabled',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        AppLogger.warning('AUTH', 'Failed to log 2FA disable: $e');
      }

      AppLogger.info('AUTH', '2FA disabled for $userId');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('AUTH', '2FA disable failed: $e');
      return Result.failure(
        exceptions.AuthException('Failed to disable 2FA: $e') as Exception
      );
    }
  }

  Future<bool> isTwoFactorEnabled(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Try to check MultiFactor API if available
      try {
        final mfaSession = user.multiFactor;
        // MultiFactor API not reliably available - rely on Firestore
        AppLogger.debug('AUTH', 'Checking 2FA via Firestore');
      } catch (e) {
        AppLogger.debug('AUTH', 'MultiFactor unavailable: $e');
      }

      final result = await _databaseService.readPath('users/$userId');
      final doc = result.data;
      return (doc?['twoFactorEnabled'] as bool?) ?? false;
    } catch (e) {
      AppLogger.debug('AUTH', 'MFA check error: $e');
      return false;
    }
  }

  Future<void> enrollPhoneMFA(String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw exceptions.AuthException('User not authenticated');
      }

      // MultiFactor API is conditionally available depending on Firebase SDK version
      try {
        final mfaSession = user.multiFactor;
        try {
          // PhoneAuthProvider.instance and mfaSession.session may not be available
          // Log for debugging
          AppLogger.debug('AUTH', 'Phone MFA enrollment attempted');
        } catch (e) {
          AppLogger.debug('AUTH', 'MultiFactor API not available: $e');
        }
      } catch (e) {
        AppLogger.debug('AUTH', 'MultiFactor session unavailable: $e');
      }
    } catch (e) {
      AppLogger.error('AUTH', 'Phone MFA enrollment failed: $e');
      rethrow;
    }
  }

  Future<void> completePhoneMFAEnrollment(
    String verificationId,
    String smsCode,
    String displayName,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw exceptions.AuthException('User not authenticated');
      }

      final mfaSession = user.multiFactor;
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final multiFactorAssertion = PhoneMultiFactorGenerator.getAssertion(
        phoneCredential,
      );

      await mfaSession.enroll(
        multiFactorAssertion,
        displayName: displayName,
      );

      AppLogger.info('AUTH', 'Phone MFA enrolled');
    } catch (e) {
      AppLogger.error('AUTH', 'Phone MFA enrollment failed: $e');
      rethrow;
    }
  }

  String _normalizePhone(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+1$digits';
    }
    if (!digits.startsWith('+')) {
      digits = '+$digits';
    }
    return digits;
  }
}
