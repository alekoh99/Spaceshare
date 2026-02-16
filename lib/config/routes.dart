// Routes Configuration

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/phone_entry_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/matching/swipe_feed_screen.dart';
import '../screens/matching/match_detail_screen.dart';
import '../screens/messaging/conversations_screen.dart';
import '../screens/messaging/chat_screen.dart';
import '../screens/payments/payment_split_screen.dart';
import '../screens/payments/payment_history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/settings/notification_preferences_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/paywall/paywall_screen.dart';

class RouteConfig {
  static const String splash = '/splash';
  static const String phoneEntry = '/auth/phone';
  static const String otpVerification = '/auth/otp';
  static const String profileSetup = '/auth/profile-setup';
  static const String compatibilityQuiz = '/auth/quiz';
  
  static const String home = '/home';
  static const String swipeFeed = '/discover';
  static const String matchDetail = '/match/:id';
  static const String activeMatches = '/matches';
  
  static const String conversations = '/messages';
  static const String chatScreen = '/chat/:matchId';
  
  static const String paymentSplit = '/pay/split';
  static const String paymentHistory = '/pay/history';
  static const String paymentDetail = '/pay/:id';
  
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String settings = '/settings';
  
  static const String notifications = '/notifications';
  static const String help = '/help';
  static const String paywall = '/paywall';
}

class GetPages {
  static List<GetPage> pages = [
    // Splash
    GetPage(
      name: RouteConfig.splash,
      page: () => const SplashScreen(),
      transition: Transition.fade,
    ),
    
    // Auth flow
    GetPage(
      name: RouteConfig.phoneEntry,
      page: () => PhoneEntryScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RouteConfig.otpVerification,
      page: () {
        final phone = Get.arguments?['phone'] as String? ?? '';
        return OTPVerificationScreen(phone: phone);
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RouteConfig.profileSetup,
      page: () => const ProfileSetupScreen(),
      transition: Transition.rightToLeft,
    ),
    
    // Main app
    GetPage(
      name: RouteConfig.home,
      page: () => const HomeScreen(),
      transition: Transition.fade,
    ),
    GetPage(
      name: RouteConfig.swipeFeed,
      page: () => const SwipeFeedScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RouteConfig.matchDetail,
      page: () {
        final match = Get.arguments?['match'];
        return match != null ? MatchDetailScreen(match: match) : const SizedBox.shrink();
      },
      transition: Transition.zoom,
    ),
    GetPage(
      name: RouteConfig.activeMatches,
      page: () => const ConversationsScreen(),
      transition: Transition.rightToLeft,
    ),
    
    // Messaging
    GetPage(
      name: RouteConfig.conversations,
      page: () => const ConversationsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RouteConfig.chatScreen,
      page: () {
        final conversationId = Get.arguments?['conversationId'] as String? ?? '';
        final otherUserId = Get.arguments?['otherUserId'] as String? ?? '';
        return ChatScreen(
          conversationId: conversationId,
          otherUserId: otherUserId,
        );
      },
      transition: Transition.rightToLeft,
    ),
    
    // Payments
    GetPage(
      name: RouteConfig.paymentSplit,
      page: () {
        final paymentId = Get.arguments?['paymentId'] as String? ?? '';
        return PaymentSplitScreen(paymentId: paymentId);
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RouteConfig.paymentHistory,
      page: () => const PaymentHistoryScreen(),
      transition: Transition.rightToLeft,
    ),
    
    // Profile
    GetPage(
      name: RouteConfig.profile,
      page: () => const ProfileScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RouteConfig.profileEdit,
      page: () => const EditProfileScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RouteConfig.settings,
      page: () => NotificationPreferencesScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RouteConfig.notifications,
      page: () => const NotificationsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RouteConfig.paywall,
      page: () => const PaywallScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}
