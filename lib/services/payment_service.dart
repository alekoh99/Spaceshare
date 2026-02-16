import 'package:get/get.dart';
import '../models/payment_model.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IPaymentService {
  Future<Result<Payment>> createPayment({
    required String userId,
    required String listingId,
    required double amount,
    required String currency,
  });

  Future<Result<Payment>> getPayment(String paymentId);
  Future<Result<List<Payment>>> getUserPayments(String userId);
  Future<Result<void>> updatePaymentStatus(String paymentId, String status);
  Future<Result<List<Payment>>> getPaymentHistory(String userId, {int limit = 50});
  Future<Result<Map<String, dynamic>>> createPaymentIntent({
    required double amount,
    required String currency,
    required String type,
    required String description,
    required String recipientUserId,
    required dynamic dueDate,
  });
  Future<Result<Map<String, dynamic>>> confirmPayment(String paymentId);
  Future<Result<double>> calculateFee(double amount);
  Future<Result<void>> fileDispute(String paymentId, String reason);
}

class PaymentService implements IPaymentService {
  late final UnifiedDatabaseService _databaseService;

  PaymentService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize PaymentService: $e');
    }
  }

  @override
  Future<Result<Payment>> createPayment({
    required String userId,
    required String listingId,
    required double amount,
    required String currency,
  }) async {
    try {
      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final payment = Payment(
        paymentId: paymentId,
        fromUserId: userId,
        toUserId: '',
        amount: amount,
        currency: currency,
        type: 'rent',
        description: 'Rent payment for listing $listingId',
        stripePaymentIntentId: '',
        status: 'pending',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(Duration(days: 30)),
        listingId: listingId,
      );

      final result = await _databaseService.createPath(
        'payments/$paymentId',
        payment.toJson(),
      );
      
      if (result.isSuccess()) {
        return Result<Payment>.success(payment);
      } else {
        return Result<Payment>.failure(result.exception ?? Exception('Failed to create payment'));
      }
    } catch (e) {
      return Result<Payment>.failure(Exception('Error creating payment: $e'));
    }
  }

  @override
  Future<Result<Payment>> getPayment(String paymentId) async {
    try {
      final result = await _databaseService.readPath('payments/$paymentId');
      if (result.isSuccess() && result.data != null) {
        return Result<Payment>.success(Payment.fromJson(result.data!));
      }
      return Result<Payment>.failure(result.exception ?? Exception('Payment not found'));
    } catch (e) {
      return Result<Payment>.failure(Exception('Error fetching payment: $e'));

    }
  }

  @override
  Future<Result<List<Payment>>> getUserPayments(String userId) async {
    try {
      final result = await _databaseService.readPath('payments');
      if (result.isSuccess() && result.data != null) {
        final paymentsData = Map<String, dynamic>.from(result.data!);
        final payments = <Payment>[];
        
        paymentsData.forEach((key, value) {
          final payData = Map<String, dynamic>.from(value as Map);
          final payment = Payment.fromJson(payData);
          if (payment.fromUserId == userId || payment.toUserId == userId) {
            payments.add(payment);
          }
        });
        
        return Result<List<Payment>>.success(payments);
      }
      return Result<List<Payment>>.success([]);
    } catch (e) {
      return Result<List<Payment>>.failure(Exception('Error fetching user payments: $e'));
    }
  }

  @override
  Future<Result<void>> updatePaymentStatus(String paymentId, String status) async {
    try {
      await _databaseService.updatePath(
        'payments/$paymentId',
        {
          'status': status,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      return Result<void>.success(null);
    } catch (e) {
      return Result<void>.failure(Exception('Error updating payment status: $e'));
    }
  }

  @override
  Future<Result<List<Payment>>> getPaymentHistory(String userId, {int limit = 50}) async {
    try {
      final result = await getUserPayments(userId);
      final result_value = result.getOrNull();
      if (result_value != null && result_value is List<Payment>) {
        return Result<List<Payment>>.success(result_value.take(limit).toList());
      }
      return Result<List<Payment>>.success([]);
    } catch (e) {
      return Result<List<Payment>>.failure(Exception('Error fetching payment history: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createPaymentIntent({
    required double amount,
    required String currency,
    required String type,
    required String description,
    required String recipientUserId,
    required dynamic dueDate,
  }) async {
    try {
      final intent = {
        'paymentId': 'pay_${DateTime.now().millisecondsSinceEpoch}',
        'paymentIntentId': 'pi_${DateTime.now().millisecondsSinceEpoch}',
        'amount': (amount * 100).toInt(),
        'currency': currency,
        'recipientUserId': recipientUserId,
        'type': type,
        'description': description,
        'dueDate': dueDate,
        'status': 'requires_payment_method',
        'createdAt': DateTime.now().toIso8601String(),
      };
      return Result<Map<String, dynamic>>.success(intent);
    } catch (e) {
      return Result<Map<String, dynamic>>.failure(Exception('Error creating payment intent: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> confirmPayment(String paymentId) async {
    try {
      final payment = await getPayment(paymentId);
      final paymentData = payment.getOrNull();
      if (paymentData == null) {
        return Result<Map<String, dynamic>>.failure(Exception('Payment not found'));
      }
      
      final confirmation = {
        'paymentId': paymentId,
        'status': 'succeeded',
        'confirmedAt': DateTime.now().toIso8601String(),
      };
      
      // Update payment status
      await updatePaymentStatus(paymentId, 'completed');
      
      return Result<Map<String, dynamic>>.success(confirmation);
    } catch (e) {
      return Result<Map<String, dynamic>>.failure(Exception('Error confirming payment: $e'));
    }
  }

  @override
  Future<Result<double>> calculateFee(double amount) async {
    try {
      final fee = amount * 0.029 + 0.30; // 2.9% + $0.30
      return Result<double>.success(fee);
    } catch (e) {
      return Result<double>.failure(Exception('Error calculating fee: $e'));
    }
  }

  @override
  Future<Result<void>> fileDispute(String paymentId, String reason) async {
    try {
      await _databaseService.updatePath(
        'payments/$paymentId',
        {
          'status': 'disputed',
          'dispute': {
            'reason': reason,
            'filedAt': DateTime.now().toIso8601String(),
          },
        },
      );
      return Result<void>.success(null);
    } catch (e) {
      return Result<void>.failure(Exception('Error filing dispute: $e'));
    }
  }
}
