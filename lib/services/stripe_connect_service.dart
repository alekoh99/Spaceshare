import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IStripeConnectService {
  Future<Result<String>> createConnectAccount(String userId);
  Future<Result<Map<String, dynamic>>> getConnectStatus(String userId);
  Future<Result<Map<String, dynamic>>> getConnectAccount(String userId);
  Future<Result<List<Map<String, dynamic>>>> getPaymentSplitsByUser(String userId);
  Future<Result<Map<String, dynamic>>> createPaymentSplit(Map<String, dynamic> splitData);
  Future<Result<void>> confirmPaymentSplit(String splitId, String userId);
  Future<Result<List<Map<String, dynamic>>>> getPayoutsByUser(String userId);
  Future<Result<Map<String, dynamic>>> getUserPayoutStats(String userId);
  Future<Result<Map<String, dynamic>>> createPayout({
    required String userId,
    required double amount,
    required String currency,
    List<String>? paymentIds,
  });
}

class StripeConnectService implements IStripeConnectService {
  late final UnifiedDatabaseService _databaseService;

  StripeConnectService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize StripeConnectService: $e');
    }
  }

  @override
  Future<Result<String>> createConnectAccount(String userId) async {
    try {
      final connectId = 'acct_${DateTime.now().millisecondsSinceEpoch}';
      
      final result = await _databaseService.updateProfile(userId, {
        'stripeConnectId': connectId,
      });

      if (result.isSuccess()) {
        return Result<String>.success(connectId);
      }
      return Result<String>.failure(result.exception ?? Exception('Failed to create connect account'));
    } catch (e) {
      return Result<String>.failure(Exception('Error creating connect account: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getConnectStatus(String userId) async {
    try {
      final userResult = await _databaseService.getProfile(userId);
      
      if (!userResult.isSuccess()) {
        return Result<Map<String, dynamic>>.failure(
          userResult.exception ?? Exception('User not found'),
        );
      }

      final status = {
        'userId': userId,
        'connectId': userResult.data?.stripeConnectId,
        'isConnected': userResult.data?.stripeConnectId != null,
      };

      return Result<Map<String, dynamic>>.success(status);
    } catch (e) {
      return Result<Map<String, dynamic>>.failure(Exception('Error fetching connect status: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getConnectAccount(String userId) async {
    try {
      return await getConnectStatus(userId);
    } catch (e) {
      return Result<Map<String, dynamic>>.failure(Exception('Error getting connect account: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getPaymentSplitsByUser(String userId) async {
    try {
      final result = await _databaseService.readPath('paymentSplits');
      if (result.isSuccess() && result.data != null) {
        final splits = <Map<String, dynamic>>[];
        final splitsData = Map<String, dynamic>.from(result.data!);
        
        splitsData.forEach((key, value) {
          final split = Map<String, dynamic>.from(value as Map);
          if (split['userId'] == userId) {
            splits.add(split);
          }
        });
        
        return Result<List<Map<String, dynamic>>>.success(splits);
      }
      return Result<List<Map<String, dynamic>>>.success([]);
    } catch (e) {
      return Result<List<Map<String, dynamic>>>.failure(Exception('Error fetching payment splits: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createPaymentSplit(Map<String, dynamic> splitData) async {
    try {
      final splitId = 'split_${DateTime.now().millisecondsSinceEpoch}';
      final split = {
        'splitId': splitId,
        ...splitData,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      await _databaseService.createPath('paymentSplits/$splitId', split);
      return Result<Map<String, dynamic>>.success(split);
    } catch (e) {
      return Result<Map<String, dynamic>>.failure(Exception('Error creating payment split: $e'));
    }
  }

  @override
  Future<Result<void>> confirmPaymentSplit(String splitId, String userId) async {
    try {
      await _databaseService.updatePath('paymentSplits/$splitId', {
        'status': 'confirmed',
        'confirmedBy': userId,
        'confirmedAt': DateTime.now().toIso8601String(),
      });
      return Result<void>.success(null);
    } catch (e) {
      return Result<void>.failure(Exception('Error confirming payment split: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getPayoutsByUser(String userId) async {
    try {
      final result = await _databaseService.readPath('payouts');
      if (result.isSuccess() && result.data != null) {
        final payouts = <Map<String, dynamic>>[];
        final payoutsData = Map<String, dynamic>.from(result.data!);
        
        payoutsData.forEach((key, value) {
          final payout = Map<String, dynamic>.from(value as Map);
          if (payout['userId'] == userId) {
            payouts.add(payout);
          }
        });
        
        payouts.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
        return Result<List<Map<String, dynamic>>>.success(payouts);
      }
      return Result<List<Map<String, dynamic>>>.success([]);
    } catch (e) {
      return Result<List<Map<String, dynamic>>>.failure(Exception('Error fetching payouts: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getUserPayoutStats(String userId) async {
    try {
      final payoutsResult = await getPayoutsByUser(userId);
      if (!payoutsResult.isSuccess()) {
        return Result<Map<String, dynamic>>.failure(
          payoutsResult.exception ?? Exception('Failed to get payouts'),
        );
      }
      
      final payouts = payoutsResult.data ?? [];
      double totalPaidOut = 0;
      int payoutCount = 0;
      
      for (final payout in payouts) {
        if (payout['status'] == 'completed') {
          totalPaidOut += (payout['amount'] as num).toDouble();
          payoutCount++;
        }
      }
      
      final stats = {
        'totalPaidOut': totalPaidOut,
        'payoutCount': payoutCount,
        'averagePayout': payoutCount > 0 ? totalPaidOut / payoutCount : 0.0,
        'nextPayoutDate': _calculateNextPayoutDate(),
      };
      
      return Result<Map<String, dynamic>>.success(stats);
    } catch (e) {
      return Result<Map<String, dynamic>>.failure(Exception('Error calculating payout stats: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createPayout({
    required String userId,
    required double amount,
    required String currency,
    List<String>? paymentIds,
  }) async {
    try {
      final payoutId = 'payout_${DateTime.now().millisecondsSinceEpoch}';
      final payout = {
        'payoutId': payoutId,
        'userId': userId,
        'amount': amount,
        'currency': currency,
        'paymentIds': paymentIds ?? [],
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      await _databaseService.createPath('payouts/$payoutId', payout);
      return Result<Map<String, dynamic>>.success(payout);
    } catch (e) {
      return Result<Map<String, dynamic>>.failure(Exception('Error creating payout: $e'));
    }
  }

  String _calculateNextPayoutDate() {
    final now = DateTime.now();
    final nextPayout = now.add(Duration(days: 7 - now.weekday));
    return nextPayout.toIso8601String();
  }
}
