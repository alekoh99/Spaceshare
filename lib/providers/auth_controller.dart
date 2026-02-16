import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/auth_user_service.dart';
import '../services/unified_database_service.dart';
import '../services/database_health_service.dart';
import '../services/cache_manager.dart';
import '../services/sync_manager.dart';
import '../services/api_client.dart';
import '../utils/logger.dart';
import '../utils/navigation_helper.dart';

class AuthController extends GetxController {
  late FirebaseAuthService _firebaseAuthService;
  late IUserService _userService;

  FirebaseAuthService get authService => _firebaseAuthService;
  IUserService get userService => _userService;

  // State variables
  final isAuthenticated = false.obs;
  final isLoading = false.obs;
  final currentUserId = Rx<String?>(null);
  final currentUser = Rx<UserProfile?>(null);
  final phoneVerified = false.obs;
  final emailVerified = false.obs;
  final error = Rx<String?>(null);
  final verificationId = Rx<String?>(null);
  
  // Performance optimization
  final isInitialized = false.obs;
  bool _isListenerSetup = false;
  
  // Track if we're in an explicit sign-in flow to prevent navigation conflicts
  bool _isInSignInFlow = false;

  // Computed property
  bool get isLoggedIn => isAuthenticated.value && currentUserId.value != null;

  @override
  void onInit() {
    super.onInit();
    
    _firebaseAuthService = FirebaseAuthService();
    try {
      _userService = Get.find<IUserService>();
    } catch (e) {
      AppLogger.error('AUTH', 'Failed to resolve user service: $e');
      rethrow;
    }
    
    _setupAuthListener();
    checkAuthStatus();
    isInitialized.value = true;
  }

  void _setupAuthListener() {
    if (_isListenerSetup) return;
    _isListenerSetup = true;
    
    try {
      _firebaseAuthService.authStateChanges().listen(
        (user) {
          if (user != null) {
            AppLogger.debug('AUTH', 'Auth state changed: User logged in - ${user.uid}');
            currentUserId.value = user.uid;
            isAuthenticated.value = true;
            
            // Skip navigation if we're in an explicit sign-in flow (sign-in method will handle it)
            if (_isInSignInFlow) {
              AppLogger.debug('AUTH', 'Auth listener: Skipping navigation (sign-in flow in progress)');
              return;
            }
            
            // Load profile and handle navigation (only for implicit auth state changes)
            loadUserProfile().then((_) {
              final hasProfile = currentUser.value != null;
              AppLogger.info('AUTH', 'Profile loaded from auth listener: hasProfile=$hasProfile');
              
              // Handle navigation after profile is loaded
              Future.delayed(const Duration(milliseconds: 300), () {
                if (hasProfile) {
                  AppLogger.info('AUTH', 'Auth listener: Navigating to home');
                  NavigationHelper.goToHome().catchError((e) {
                    AppLogger.error('AUTH', 'Navigation failed: $e');
                  });
                } else {
                  AppLogger.info('AUTH', 'Auth listener: Navigating to profile setup');
                  NavigationHelper.goToProfileSetup().catchError((e) {
                    AppLogger.error('AUTH', 'Navigation failed: $e');
                  });
                }
              });
            }).catchError((e) {
              AppLogger.debug('AUTH', 'Profile load in auth listener: $e');
            });
          } else {
            AppLogger.debug('AUTH', 'Auth state changed: User logged out');
            currentUserId.value = null;
            isAuthenticated.value = false;
            currentUser.value = null;
          }
        },
        onError: (e) {
          AppLogger.error('AUTH', 'Auth listener error: $e');
        },
      );
    } catch (e) {
      AppLogger.error('AUTH', 'Failed to setup auth listener: $e');
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final uid = await _firebaseAuthService.getCurrentUserId();
      if (uid != null) {
        currentUserId.value = uid;
        isAuthenticated.value = true;
        await loadUserProfile();
      }
    } catch (e) {
      AppLogger.error('AUTH', 'Failed to check auth status: $e');
    }
  }

  Future<void> sendOTP(String phone) async {
    try {
      isLoading.value = true;
      error.value = null;
      final verId = await _firebaseAuthService.sendOTP(phone);
      verificationId.value = verId;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOTP(String phone, String otp) async {
    try {
      if (verificationId.value == null) {
        throw Exception('Verification ID not found. Please request OTP again.');
      }

      _isInSignInFlow = true;
      isLoading.value = true;
      error.value = null;

      final userId = await _firebaseAuthService.verifyOTP(
        phone,
        otp,
        verificationId.value!,
      );

      currentUserId.value = userId;
      isAuthenticated.value = true;
      phoneVerified.value = true;

      AppLogger.info('AUTH', 'User authenticated with OTP: $userId');

      // Wait for auth listener to load the profile
      await Future.delayed(Duration(milliseconds: 500));
      
      final hasProfile = currentUser.value != null;
      AppLogger.info('AUTH', 'After auth listener: hasProfile=$hasProfile');

      // Navigate based on profile existence
      if (isAuthenticated.value && currentUserId.value != null) {
        if (!hasProfile) {
          AppLogger.info('AUTH', 'Navigating to profile setup');
          await NavigationHelper.goToProfileSetup();
        } else {
          AppLogger.info('AUTH', 'Navigating to home');
          await NavigationHelper.goToHome();
        }
      }
    } catch (e) {
      error.value = e.toString();
      AppLogger.error('AUTH', 'OTP verification failed: $e');
    } finally {
      _isInSignInFlow = false;
      isLoading.value = false;
    }
  }

  Future<void> createProfile(UserProfile profile) async {
    try {
      if (currentUserId.value == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info('AUTH', 'Starting profile creation for user: ${profile.userId}');
      isLoading.value = true;
      error.value = null;

      AppLogger.info('AUTH', 'Calling _userService.updateUserProfile()');
      await _userService.updateUserProfile(profile.userId, profile);
      AppLogger.info('AUTH', 'Profile created successfully');
      
      currentUser.value = profile;
      AppLogger.info('AUTH', 'Profile set in currentUser');
    } catch (e) {
      AppLogger.error('AUTH', 'Error creating profile', e);
      error.value = e.toString();
      rethrow; // Re-throw to let caller handle it
    } finally {
      isLoading.value = false;
      AppLogger.info('AUTH', 'Profile creation finally block - isLoading set to false');
    }
  }

  Future<void> loadUserProfile() async {
    try {
      if (currentUserId.value == null) {
        AppLogger.debug('AUTH', 'loadUserProfile: No user ID available');
        return;
      }
      isLoading.value = true;
      error.value = null;

      // Perform health check first to detect issues early
      try {
        final healthService = Get.find<DatabaseHealthService>();
        await healthService.performHealthCheck();
        final health = healthService.getHealthSummary();
        
        if (!healthService.isAnyDatabaseAvailable()) {
          AppLogger.warning('AUTH', 'No databases available: $health');
          error.value = 'Database connection issues detected. Please check your internet connection.';
          currentUser.value = null;
          return;
        }
      } catch (e) {
        AppLogger.debug('AUTH', 'Health check service not available: $e');
        // Continue anyway - health service might not be initialized
      }

      // Try unified database service with profile sync
      // This ensures that profiles in PostgreSQL are synced to Firestore
      final unifiedDb = Get.find<UnifiedDatabaseService>();
      final result = await unifiedDb.ensureProfileSync(currentUserId.value!);
      if (result.isSuccess()) {
        currentUser.value = result.getOrNull();
        AppLogger.info('AUTH', 'User profile loaded: ${currentUser.value?.name}');
      } else {
        AppLogger.debug('AUTH', 'Unified DB profile load failed: ${result.getExceptionOrNull()}');
        currentUser.value = null;
        // Don't set error - this is not an error for new users
      }
    } catch (e) {
      AppLogger.error('AUTH', 'Unexpected error loading profile: $e');
      error.value = 'Failed to load profile';
      currentUser.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile(UserProfile updates) async {
    try {
      if (currentUserId.value == null) {
        throw Exception('User not authenticated');
      }

      isLoading.value = true;
      error.value = null;

      await _userService.updateUserProfile(currentUserId.value!, updates);
      currentUser.value = updates;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      error.value = null;

      // Clear cache before signing out
      try {
        final cacheManager = CacheManager();
        await cacheManager.clearAll();
        AppLogger.info('AUTH', 'Cache cleared on sign out');
      } catch (e) {
        AppLogger.warning('AUTH', 'Failed to clear cache on sign out: $e');
      }

      await _firebaseAuthService.signOut();

      currentUserId.value = null;
      isAuthenticated.value = false;
      currentUser.value = null;
      phoneVerified.value = false;
      emailVerified.value = false;
      verificationId.value = null;
      
      AppLogger.info('AUTH', 'User signed out successfully');
    } catch (e) {
      error.value = e.toString();
      AppLogger.error('AUTH', 'Sign out error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      _isInSignInFlow = true;
      isLoading.value = true;
      error.value = null;

      final userCredential = await _firebaseAuthService.signInWithEmail(email, password);
      final uid = userCredential?.user?.uid;

      if (uid != null) {
        currentUserId.value = uid;
        isAuthenticated.value = true;
        emailVerified.value = userCredential!.user?.emailVerified ?? false;
        
        AppLogger.info('AUTH', 'Email sign-in success: ${userCredential.user?.email}');
        
        // Load profile and navigate explicitly (don't rely only on auth listener)
        await loadUserProfile();
        final hasProfile = currentUser.value != null;
        
        // Wait a bit for auth state to stabilize
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (hasProfile) {
          AppLogger.info('AUTH', 'Email sign-in: Navigating to home');
          await NavigationHelper.goToHome();
        } else {
          AppLogger.info('AUTH', 'Email sign-in: Navigating to profile setup');
          await NavigationHelper.goToProfileSetup();
        }
      } else {
        error.value = 'Failed to get user ID after sign-in';
        isAuthenticated.value = false;
        AppLogger.error('AUTH', 'Email sign-in failed: No UID returned');
      }
    } catch (e) {
      error.value = e.toString();
      // Reset auth state on error
      currentUserId.value = null;
      isAuthenticated.value = false;
      currentUser.value = null;
      AppLogger.error('AUTH', 'Email sign-in failed: $e');
    } finally {
      isLoading.value = false;
      _isInSignInFlow = false;
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      _isInSignInFlow = true;
      isLoading.value = true;
      error.value = null;

      final userCredential = await _firebaseAuthService.signUpWithEmail(email, password);
      final uid = userCredential?.user?.uid;

      if (uid != null) {
        currentUserId.value = uid;
        isAuthenticated.value = true;
        emailVerified.value = false;
        
        AppLogger.info('AUTH', 'User account created: $uid');
        
        // Try to load user profile (if it exists)
        try {
          await loadUserProfile();
          AppLogger.info('AUTH', 'User profile loaded after signup');
        } catch (e) {
          AppLogger.debug('AUTH', 'No profile found after signup (expected for new users): $e');
          currentUser.value = null;
        }
        
        // Wait a bit for auth state to stabilize
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Navigate to profile setup (for new users, they need to set up their profile)
        if (isAuthenticated.value && error.value == null) {
          AppLogger.info('AUTH', 'Navigating to profile setup after signup');
          await NavigationHelper.goToProfileSetup();
        }
      } else {
        error.value = 'Failed to create account';
        isAuthenticated.value = false;
        AppLogger.error('AUTH', 'Signup failed: No UID returned');
      }
    } catch (e) {
      error.value = e.toString();
      currentUserId.value = null;
      isAuthenticated.value = false;
      currentUser.value = null;
      AppLogger.error('AUTH', 'Email sign-up failed: $e');
    } finally {
      isLoading.value = false;
      _isInSignInFlow = false;
    }
  }

  Future<void> signInWithGoogle() async {
    late final String? uid;
    try {
      _isInSignInFlow = true;
      isLoading.value = true;
      error.value = null;

      final userCredential = await _firebaseAuthService.signInWithGoogle();
      
      if (userCredential == null) {
        error.value = 'Google sign-in was cancelled';
        return;
      }
      
      uid = userCredential.user?.uid;

      if (uid != null) {
        currentUserId.value = uid;
        isAuthenticated.value = true;
        phoneVerified.value = userCredential.user?.phoneNumber != null;
        emailVerified.value = userCredential.user?.emailVerified ?? false;
        
        AppLogger.info('AUTH', 'User authenticated with Google: $uid');
        
        // Wait for auth listener to load the profile
        await Future.delayed(Duration(milliseconds: 500));
        
        final hasProfile = currentUser.value != null;
        AppLogger.info('AUTH', 'After auth listener: hasProfile=$hasProfile');
        
        // Ensure we only navigate if authenticated
        if (isAuthenticated.value && currentUserId.value != null) {
          AppLogger.debug('AUTH', 'Navigation: hasProfile=$hasProfile, navigating...');
          // Navigate to profile setup if no profile exists (new user)
          if (!hasProfile) {
            AppLogger.info('AUTH', 'New user detected, navigating to profile setup');
            await NavigationHelper.goToProfileSetup();
          } else {
            AppLogger.info('AUTH', 'Existing user detected, navigating to home');
            await NavigationHelper.goToHome();
          }
        }
      } else {
        error.value = 'Failed to get user ID after sign-in';
        isAuthenticated.value = false;
      }
    } catch (e) {
      error.value = 'Sign-in failed: ${e.toString()}';
      AppLogger.error('AUTH', 'Google sign-in error: $e');
      // Reset auth state on error
      currentUserId.value = null;
      isAuthenticated.value = false;
      currentUser.value = null;
    } finally {
      _isInSignInFlow = false;
      isLoading.value = false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      isLoading.value = true;
      error.value = null;

      if (email.isEmpty) {
        throw Exception('Email is required');
      }

      if (!GetUtils.isEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      // Use Firebase Authentication to send password reset email
      await _firebaseAuthService.sendPasswordResetEmail(email);
      
      AppLogger.info('AUTH', 'Password reset email sent to: $email');
    } catch (e) {
      error.value = e.toString();
      AppLogger.error('AUTH', 'Password reset error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    AppLogger.info('AuthController', 'Disposing controller resources');
    _isListenerSetup = false;
    super.onClose();
  }

}
