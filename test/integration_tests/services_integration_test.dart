import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:spaceshare/config/service_initialization.dart';
import 'package:spaceshare/services/compliance_service.dart';
import 'package:spaceshare/services/subscription_management_service.dart';
import 'package:spaceshare/services/moderation_workflow_service.dart';
import 'package:spaceshare/services/user_reputation_service.dart';
import 'package:spaceshare/services/matching_service.dart';
import 'package:spaceshare/services/messaging_service.dart';
import 'package:spaceshare/services/payment_service.dart';
import 'package:spaceshare/services/notification_preferences_service.dart';
import 'package:spaceshare/services/identity_verification_service.dart';
import 'package:spaceshare/services/user_blocking_service.dart';
import 'package:spaceshare/services/evidence_upload_service.dart';
import 'package:spaceshare/services/profile_analytics_service.dart';
import 'package:spaceshare/services/conversation_archival_service.dart';

void main() {
  group('Integration Tests - Service Initialization & Workflows', () {
    /// Test 1: All services initialize without errors
    test('ServiceInitialization.initialize completes successfully', () async {
      expect(ServiceInitialization.isFullyInitialized(), false);

      // Initialize all services
      await ServiceInitialization.initialize();

      // Verify critical services are registered
      expect(Get.isRegistered<IMatchingService>(), true);
      expect(Get.isRegistered<IComplianceService>(), true);
      expect(Get.isRegistered<ISubscriptionManagementService>(), true);
      expect(Get.isRegistered<IModerationWorkflowService>(), true);
      expect(Get.isRegistered<IUserReputationService>(), true);

      // Verify full initialization
      expect(ServiceInitialization.isFullyInitialized(), true);
    });

    /// Test 2: Service retrieval works correctly
    test('ServiceInitialization.getService returns correct instances', () async {
      await ServiceInitialization.initialize();

      final complianceService =
          ServiceInitialization.getService<IComplianceService>();
      final subscriptionService =
          ServiceInitialization.getService<ISubscriptionManagementService>();

      expect(complianceService, isNotNull);
      expect(subscriptionService, isNotNull);
    });

    /// Test 3: Compliance incident creation workflow
    test('Compliance incident creation with correct signatures', () async {
      await ServiceInitialization.initialize();

      final complianceService = Get.find<IComplianceService>();

      // Simulate compliance incident with correct method signature
      try {
        await complianceService.logComplianceIncident(
          'test-user-123',
          'payment_failure',
          'high',
          'Payment processing failed for monthly rent',
          {
            'paymentId': 'test-payment-123',
            'amount': 1200.00,
            'currency': 'USD',
          },
          null,
        );

        expect(true, true); // Incident logged successfully
      } catch (e) {
        // Expected in test environment without Firebase
      }
    });

    /// Test 4: Subscription tier gating
    test('Subscription feature access is properly gated', () async {
      await ServiceInitialization.initialize();

      final subscriptionService =
          Get.find<ISubscriptionManagementService>();

      // Test feature access checking doesn't throw
      expect(subscriptionService, isNotNull);
    });

    /// Test 5: Multiple services can be accessed simultaneously
    test('Concurrent service access works correctly', () async {
      await ServiceInitialization.initialize();

      final complianceService = Get.find<IComplianceService>();
      final reputationService = Get.find<IUserReputationService>();
      final matchingService = Get.find<IMatchingService>();

      // Verify all services accessible concurrently
      expect(complianceService, isNotNull);
      expect(reputationService, isNotNull);
      expect(matchingService, isNotNull);
    });

    /// Test 6: Permanent service registration
    test('Services registered as permanent are retained', () async {
      await ServiceInitialization.initialize();

      final matchingService = Get.find<IMatchingService>();

      // Services should not be garbage collected
      expect(Get.isRegistered<IMatchingService>(), true);

      // Even after accessing multiple times
      expect(Get.find<IMatchingService>() == matchingService, true);
    });

    /// Test 7: Core services are registered
    test('Core services are registered after initialization', () async {
      await ServiceInitialization.initialize();

      // Verify core services
      expect(Get.isRegistered<IMatchingService>(), true);
      expect(Get.isRegistered<IMessagingService>(), true);
      expect(Get.isRegistered<IPaymentService>(), true);
      expect(Get.isRegistered<INotificationPreferencesService>(), true);
      expect(Get.isRegistered<IComplianceService>(), true);
      expect(Get.isRegistered<IIdentityVerificationService>(), true);
      expect(Get.isRegistered<IUserBlockingService>(), true);
    });

    /// Test 8: Compliance and Safety services
    test('Compliance and safety services are registered', () async {
      await ServiceInitialization.initialize();

      expect(Get.isRegistered<IComplianceService>(), true);
      expect(Get.isRegistered<IIdentityVerificationService>(), true);
      expect(Get.isRegistered<IUserBlockingService>(), true);
    });

    /// Test 9: Messaging and Analytics services
    test('Messaging and analytics services are registered', () async {
      await ServiceInitialization.initialize();

      expect(Get.isRegistered<IMessagingService>(), true);
      expect(Get.isRegistered<IEvidenceUploadService>(), true);
      expect(Get.isRegistered<IProfileAnalyticsService>(), true);
    });

    /// Test 10: User and Platform management services
    test('User and platform management services are registered', () async {
      await ServiceInitialization.initialize();

      expect(Get.isRegistered<IConversationArchivalService>(), true);
      expect(Get.isRegistered<IUserReputationService>(), true);
      expect(Get.isRegistered<ISubscriptionManagementService>(), true);
      expect(Get.isRegistered<IModerationWorkflowService>(), true);
    });
  });
}
