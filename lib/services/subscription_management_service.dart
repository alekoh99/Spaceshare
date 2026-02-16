import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class ISubscriptionManagementService {
  Future<Result<void>> createSubscription(String userId, String plan, double amount);
  Future<Result<Map<String, dynamic>>> getSubscription(String userId);
  Future<Result<void>> updateSubscription(String userId, String newPlan);
  Future<Result<void>> cancelSubscription(String userId);
  Future<Result<void>> renewSubscription(String userId);
  Future<Result<Map<String, dynamic>>> getUserSubscription(String userId);
}

class SubscriptionManagementService implements ISubscriptionManagementService {
  late final UnifiedDatabaseService _databaseService;

  SubscriptionManagementService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize SubscriptionManagementService: $e');
    }
  }

  @override
  Future<Result<void>> createSubscription(String userId, String plan, double amount) async {
    try {
      final subscriptionData = {
        'userId': userId,
        'plan': plan,
        'amount': amount,
        'status': 'active',
        'startDate': DateTime.now().toIso8601String(),
        'renewalDate': DateTime.now().add(Duration(days: 30)).toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      final result = await _databaseService.createPath(
        'subscriptions/$userId',
        subscriptionData,
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to create subscription: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getSubscription(String userId) async {
    try {
      final result = await _databaseService.readPath('subscriptions/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        return Result.success(result.data as Map<String, dynamic>);
      }

      return Result.failure(Exception('Subscription not found'));
    } catch (e) {
      return Result.failure(Exception('Failed to get subscription: $e'));
    }
  }

  @override
  Future<Result<void>> updateSubscription(String userId, String newPlan) async {
    try {
      final result = await _databaseService.updatePath(
        'subscriptions/$userId',
        {
          'plan': newPlan,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to update subscription: $e'));
    }
  }

  @override
  Future<Result<void>> cancelSubscription(String userId) async {
    try {
      final result = await _databaseService.updatePath(
        'subscriptions/$userId',
        {
          'status': 'cancelled',
          'cancelledAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to cancel subscription: $e'));
    }
  }

  @override
  Future<Result<void>> renewSubscription(String userId) async {
    try {
      final result = await _databaseService.updatePath(
        'subscriptions/$userId',
        {
          'renewalDate': DateTime.now().add(Duration(days: 30)).toIso8601String(),
          'lastRenewedAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to renew subscription: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getUserSubscription(String userId) async {
    try {
      final result = await _databaseService.readPath('subscriptions/$userId');
      
      if (result.isSuccess() && result.data is Map) {
        return Result.success(Map<String, dynamic>.from(result.data as Map));
      }

      return Result.failure(Exception('Subscription not found'));
    } catch (e) {
      return Result.failure(Exception('Failed to get subscription: $e'));
    }
  }
}
