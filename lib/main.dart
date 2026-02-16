import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'config/theme.dart';
import 'config/app_config.dart';
import 'config/service_initialization.dart';
import 'utils/global_error_handler.dart';
import 'utils/logger.dart';
import 'utils/app_lifecycle_handler.dart';
import 'providers/auth_controller.dart';
import 'providers/matching_controller.dart';
import 'providers/messaging_controller.dart';
import 'providers/payment_controller.dart';
import 'providers/notification_controller.dart';
import 'providers/compliance_controller.dart';
import 'providers/notification_preferences_controller.dart';
import 'providers/profile_controller.dart';
import 'services/admob_service.dart';
import 'services/adsense_web_service.dart';
import 'providers/monetization_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup global error handler
  GlobalErrorHandler.setup();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Note: Firebase Realtime Database is configured automatically upon Firebase initialization
    // No additional configuration needed - it uses the databaseURL from firebase options

    // Initialize Firebase Messaging
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
    } catch (e) {
      AppLogger.warning('FCM', 'Firebase Messaging initialization: Non-critical');
    }

    // Configure Stripe (skip on web platform)
    try {
      if (!kIsWeb) {
        Stripe.publishableKey = AppConfig.stripePublishableKey;
        await Stripe.instance.applySettings();
      }
    } catch (e) {
      AppLogger.warning('Stripe', 'Configuration: Non-critical');
    }

    // Initialize all 25+ services (dependency injection)
    await ServiceInitialization.initialize();

    // Initialize app lifecycle handler for proper cleanup on app close
    AppLifecycleHandler.initialize();

    // Initialize monetization services
    if (!kIsWeb) {
      await Get.putAsync<AdMobService>(() => AdMobService().init());
    } else {
      await Get.putAsync<AdSenseWebService>(() => AdSenseWebService().init());
    }

    // Initialize GetX controllers
    initializeControllers();

    // Setup FCM message handlers (after service initialization)
    _setupFCMHandlers();
  } catch (e, stackTrace) {
    AppLogger.error('MAIN', 'Initialization failed', e, stackTrace);
  }

  runApp(const SpaceShareApp());
  
  // Remove native splash screen after Flutter UI is displayed
  // This ensures smooth transition from native to Flutter splash
  Future.delayed(const Duration(milliseconds: 500), () {
    try {
      // The native splash screen will automatically hide when the first frame is drawn
      // This is handled by retain_image_on_launch: false in flutter_native_splash.yaml
      AppLogger.debug('MAIN', 'App startup complete - native splash will be removed');
    } catch (e) {
      AppLogger.warning('MAIN', 'Splash removal: Non-critical - $e');
    }
  });
}

/// Initialize GetX controllers (separate from services)
/// Controllers manage UI state, services handle business logic
/// NOTE: Controllers are initialized BEFORE runApp() so avoid any GetX snackbar/dialog calls
/// in their onInit() methods as the widget tree doesn't exist yet
void initializeControllers() {
  Get.put<AuthController>(AuthController());
  Get.put<MatchingController>(MatchingController());
  Get.put<MessagingController>(MessagingController());
  Get.put<PaymentController>(PaymentController());
  Get.put<NotificationController>(NotificationController());
  Get.put<ComplianceController>(ComplianceController());
  Get.put<ProfileController>(ProfileController());
  Get.put<MonetizationController>(MonetizationController());
  // NotificationPreferencesController should handle initialization errors gracefully
  // since the widget tree (Overlay) is not yet available
  Get.put<NotificationPreferencesController>(NotificationPreferencesController());
}

/// Setup Firebase Cloud Messaging handlers
/// Must be called after service initialization
void _setupFCMHandlers() {
  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Handle notification
    if (message.notification != null) {
      Get.snackbar(
        message.notification!.title ?? 'Notification',
        message.notification!.body ?? '',
      );
    }

    // Handle data payload with service routing
    if (message.data.isNotEmpty) {
      final data = message.data;
      final type = data['type'];
      // final matchId = data['matchId']; // Not used in foreground handler

      switch (type) {
        case 'message':
          // Reload messaging controller
          if (Get.isRegistered<MessagingController>()) {
            Get.find<MessagingController>().loadConversations();
          }
          break;
        case 'match':
          Get.toNamed('/matching');
          break;
        case 'payment':
          Get.toNamed('/payment');
          break;
        case 'verification':
          Get.toNamed('/identity-verification');
          break;
        case 'compliance':
          Get.toNamed('/compliance-dashboard');
          break;
        case 'moderation':
          Get.toNamed('/incident-review');
          break;
        default:
          if (kDebugMode) {
            debugPrint('Unknown notification type: $type');
          }
      }
    }
  });

  // Handle background/terminated message taps
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data.isNotEmpty) {
      final data = message.data;
      final type = data['type'];
      final matchId = data['matchId'];

      switch (type) {
        case 'message':
          if (matchId != null) {
            Get.toNamed('/chat', arguments: {'matchId': matchId});
          }
          break;
        case 'match':
          Get.toNamed('/matching');
          break;
        case 'payment':
          Get.toNamed('/payment');
          break;
        case 'compliance':
          Get.toNamed('/compliance-dashboard');
          break;
        case 'moderation':
          Get.toNamed('/incident-review');
          break;
      }
    }
  });
}

class SpaceShareApp extends StatelessWidget {
  const SpaceShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SpaceShare',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,

      // Routing
      initialRoute: '/splash',
      getPages: AppRoutes.pages,

      // Global settings
      enableLog: false,
      logWriterCallback: (String text, {bool isError = false}) {
        // Send to Crashlytics or logging service in production
        debugPrint('${isError ? '[ERROR]' : '[LOG]'} $text');
      },
    );
  }
}
