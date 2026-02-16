import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IEscrowService {
  Future<Result<String>> createEscrow(String paymentId, String payerId, String payeeId, double amount);
  Future<Result<Map<String, dynamic>>> getEscrow(String escrowId);
  Future<Result<void>> releaseEscrow(String escrowId);
  Future<Result<void>> refundEscrow(String escrowId, String reason);
}

class EscrowService implements IEscrowService {
  late final UnifiedDatabaseService _databaseService;

  EscrowService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize EscrowService: $e');
    }
  }

  @override
  Future<Result<String>> createEscrow(String paymentId, String payerId, String payeeId, double amount) async {
    try {
      final escrowId = 'escrow_${DateTime.now().millisecondsSinceEpoch}';
      
      final escrowData = {
        'escrowId': escrowId,
        'paymentId': paymentId,
        'payerId': payerId,
        'payeeId': payeeId,
        'amount': amount,
        'status': 'held',
        'createdAt': DateTime.now().toIso8601String(),
        'releasedAt': null,
        'releaseReason': null,
      };

      final result = await _databaseService.createPath(
        'escrows/$escrowId',
        escrowData,
      );

      if (result.isSuccess()) {
        return Result.success(escrowId);
      } else {
        return Result.failure(result.exception ?? Exception('Failed to create escrow'));
      }
    } catch (e) {
      return Result.failure(Exception('Failed to create escrow: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getEscrow(String escrowId) async {
    try {
      final result = await _databaseService.readPath('escrows/$escrowId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        return Result.success(result.data as Map<String, dynamic>);
      }
      return Result.failure(Exception('Escrow not found'));
    } catch (e) {
      return Result.failure(Exception('Failed to get escrow: $e'));
    }
  }

  @override
  Future<Result<void>> releaseEscrow(String escrowId) async {
    try {
      final result = await _databaseService.updatePath(
        'escrows/$escrowId',
        {
          'status': 'released',
          'releasedAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to release escrow: $e'));
    }
  }

  @override
  Future<Result<void>> refundEscrow(String escrowId, String reason) async {
    try {
      final result = await _databaseService.updatePath(
        'escrows/$escrowId',
        {
          'status': 'refunded',
          'releaseReason': reason,
          'releasedAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to refund escrow: $e'));
    }
  }
}
