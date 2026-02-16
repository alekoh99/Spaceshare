import 'package:get/get.dart';
import 'package:flutter/material.dart' as material;
import 'screens/auth/splash_screen.dart';
import 'screens/auth/auth_options_screen.dart';
import 'screens/auth/email_signin_screen.dart';
import 'screens/auth/email_signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/phone_entry_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/messaging/chat_screen.dart';
import 'screens/messaging/conversations_screen.dart';
import 'screens/matching/swipe_feed_screen.dart';
import 'screens/matching/match_detail_screen.dart';
import 'screens/payments/payment_history_screen.dart';
import 'screens/payments/payment_split_screen.dart';
import 'screens/verification/identity_verification_screen.dart';
import 'screens/compliance/compliance_dashboard_screen.dart';
import 'screens/admin/incident_review_screen.dart';
import 'screens/admin/admin_analytics_dashboard.dart';
import 'screens/settings/notification_preferences_screen.dart';
import 'screens/settings/support_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/paywall/paywall_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/privacy_settings_screen.dart';
import 'screens/profile/profile_analytics_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/onboarding/compatibility_questionnaire_screen.dart';
import 'screens/users/user_blocking_screen.dart';
import 'screens/users/user_reputation_screen.dart';
import 'screens/disputes/dispute_resolution_screen.dart';
import 'models/match_model.dart';

class AppRoutes {
  static const String home = '/';
  static const String splash = '/splash';
  static const String authOptions = '/auth-options';
  static const String emailSignIn = '/auth/email-signin';
  static const String emailSignUp = '/auth/email-signup';
  static const String forgotPassword = '/forgot-password';
  static const String phoneEntry = '/phone-entry';
  static const String otpVerification = '/otp-verification';
  static const String profileSetup = '/profile-setup';
  static const String matching = '/matching';
  static const String chat = '/chat';
  static const String conversations = '/conversations';
  static const String payment = '/payment';
  static const String payments = '/payments';
  static const String paymentSplit = '/payment-split';
  static const String identityVerification = '/identity-verification';
  static const String complianceDashboard = '/compliance-dashboard';
  static const String incidentReview = '/incident-review';
  static const String notificationPreferences = '/notification-preferences';
  static const String notificationSettings = '/notification-settings';
  static const String paywall = '/paywall';
  static const String settings = '/settings';
  static const String support = '/support';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String privacySettings = '/privacy-settings';
  static const String notifications = '/notifications';
  static const String matchDetail = '/match-detail';
  static const String profileAnalytics = '/profile-analytics';
  static const String adminAnalytics = '/admin-analytics';
  static const String compatibilityQuestionnaire = '/compatibility-questionnaire';
  static const String userBlocking = '/user-blocking';
  static const String userReputation = '/user-reputation';
  static const String disputeResolution = '/dispute-resolution';

  static List<GetPage> pages = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: authOptions,
      page: () => const AuthOptionsScreen(),
    ),
    GetPage(
      name: emailSignIn,
      page: () => const EmailSignInScreen(),
    ),
    GetPage(
      name: emailSignUp,
      page: () => const EmailSignUpScreen(),
    ),
    GetPage(
      name: forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: phoneEntry,
      page: () => PhoneEntryScreen(),
    ),
    GetPage(
      name: otpVerification,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final phone = args?['phone'] ?? '';
        return OTPVerificationScreen(phone: phone);
      },
    ),
    GetPage(
      name: profileSetup,
      page: () => ProfileSetupScreen(),
    ),
    GetPage(
      name: home,
      page: () => HomeScreen(),
    ),
    GetPage(
      name: matching,
      page: () => SwipeFeedScreen(),
    ),
    GetPage(
      name: chat,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final conversationId = args?['conversationId'] ?? '';
        final otherUserId = args?['otherUserId'] ?? '';
        return ChatScreen(
          conversationId: conversationId,
          otherUserId: otherUserId,
        );
      },
    ),
    GetPage(
      name: conversations,
      page: () => ConversationsScreen(),
    ),
    GetPage(
      name: matchDetail,
      page: () {
        final match = Get.arguments as Match?;
        if (match == null) {
          // Fallback to empty match if not provided
          return material.Scaffold(
            body: material.Center(child: const material.Text('No match selected')),
          );
        }
        return MatchDetailScreen(match: match);
      },
    ),
    GetPage(
      name: payment,
      page: () => PaymentHistoryScreen(),
    ),
    GetPage(
      name: payments,
      page: () => PaymentHistoryScreen(),
    ),
    GetPage(
      name: paymentSplit,
      page: () => PaymentSplitScreen(),
    ),
    GetPage(
      name: identityVerification,
      page: () => IdentityVerificationScreen(),
    ),
    GetPage(
      name: complianceDashboard,
      page: () => ComplianceDashboardScreen(),
    ),
    GetPage(
      name: incidentReview,
      page: () => AdminIncidentReviewScreen(),
    ),
    GetPage(
      name: notificationPreferences,
      page: () => NotificationPreferencesScreen(),
    ),
    GetPage(
      name: notificationSettings,
      page: () => NotificationPreferencesScreen(),
    ),
    GetPage(
      name: paywall,
      page: () => PaywallScreen(),
    ),
    GetPage(
      name: support,
      page: () => SupportScreen(),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
    ),
    GetPage(
      name: profile,
      page: () => ProfileScreen(),
    ),
    GetPage(
      name: editProfile,
      page: () => EditProfileScreen(),
    ),
    GetPage(
      name: privacySettings,
      page: () => PrivacySettingsScreen(),
    ),
    GetPage(
      name: notifications,
      page: () => NotificationsScreen(),
    ),
    GetPage(
      name: profileAnalytics,
      page: () => ProfileAnalyticsScreen(),
    ),
    GetPage(
      name: adminAnalytics,
      page: () => AdminAnalyticsDashboard(),
    ),
    GetPage(
      name: compatibilityQuestionnaire,
      page: () => CompatibilityQuestionnaireScreen(),
    ),
    GetPage(
      name: userBlocking,
      page: () => const UserBlockingScreen(),
    ),
    GetPage(
      name: userReputation,
      page: () {
        final userId = Get.arguments as String?;
        if (userId == null) {
          return material.Scaffold(
            body: material.Center(child: const material.Text('No user selected')),
          );
        }
        return UserReputationScreen(userId: userId);
      },
    ),
    GetPage(
      name: disputeResolution,
      page: () => const DisputeResolutionScreen(),
    ),
  ];
}
