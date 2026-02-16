import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IEscrowPaymentService {
  Future<Result<void>> initiateEscrowPayment(String paymentId, String payerId, String payeeId, double amount);
  Future<Result<void>> confirmEscrowPayment(String escrowId);
  Future<Result<void>> cancelEscrowPayment(String escrowId, String reason);
  Future<Result<List<Map<String, dynamic>>>> getEscrowPayments(String userId);
}

class EscrowPaymentService implements IEscrowPaymentService {
  late final UnifiedDatabaseService _databaseService;

  EscrowPaymentService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize EscrowPaymentService: $e');
    }
  }

  @override
  Future<Result<void>> initiateEscrowPayment(String paymentId, String payerId, String payeeId, double amount) async {
    try {
      final escrowId = 'escrow_payment_${DateTime.now().millisecondsSinceEpoch}';
      
      final data = {
        'escrowId': escrowId,
        'paymentId': paymentId,
        'payerId': payerId,
        'payeeId': payeeId,
        'amount': amount,
        'status': 'pending_confirmation',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final result = await _databaseService.createPath(
        'escrowPayments/$escrowId',
        data,
      );

      if (result.isSuccess()) {
        await _databaseService.updatePath(
          'userEscrows/$payerId',
          {escrowId: data},
        );
        await _databaseService.updatePath(
          'userEscrows/$payeeId',
          {escrowId: data},
        );
      }

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to initiate escrow payment: $e'));
    }
  }

  @override
  Future<Result<void>> confirmEscrowPayment(String escrowId) async {
    try {
      final result = await _databaseService.updatePath(
        'escrowPayments/$escrowId',
        {
          'status': 'confirmed',
          'confirmedAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to confirm escrow payment: $e'));
    }
  }

  @override
  Future<Result<void>> cancelEscrowPayment(String escrowId, String reason) async {
    try {
      final result = await _databaseService.updatePath(
        'escrowPayments/$escrowId',
        {
          'status': 'cancelled',
          'cancellationReason': reason,
          'cancelledAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to cancel escrow payment: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getEscrowPayments(String userId) async {
    try {
      final result = await _databaseService.readPath('userEscrows/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final payments = data.values
            .whereType<Map<String, dynamic>>()
            .toList();
        return Result.success(payments);
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Failed to get escrow payments: $e'));
    }
  }
}
