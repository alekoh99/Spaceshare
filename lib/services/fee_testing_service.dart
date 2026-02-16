import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IFeeTestingService {
  Future<Result<Map<String, dynamic>>> calculateFees(double amount, String feeType);
  Future<Result<void>> recordFeeTest(String feeType, double amount, double fee);
  Future<Result<List<Map<String, dynamic>>>> getFeeTestHistory();
}

class FeeTestingService implements IFeeTestingService {
  late final UnifiedDatabaseService _databaseService;

  FeeTestingService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize FeeTestingService: $e');
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> calculateFees(double amount, String feeType) async {
    try {
      double feePercentage = 0.0;
      
      switch (feeType.toLowerCase()) {
        case 'transaction':
          feePercentage = 0.029; // 2.9%
          break;
        case 'subscription':
          feePercentage = 0.05; // 5%
          break;
        case 'payout':
          feePercentage = 0.015; // 1.5%
          break;
        default:
          feePercentage = 0.02; // 2% default
      }

      final fee = amount * feePercentage;
      final totalAmount = amount + fee;

      return Result.success({
        'baseAmount': amount,
        'feeType': feeType,
        'feePercentage': feePercentage * 100,
        'fee': fee,
        'totalAmount': totalAmount,
      });
    } catch (e) {
      return Result.failure(Exception('Failed to calculate fees: $e'));
    }
  }

  @override
  Future<Result<void>> recordFeeTest(String feeType, double amount, double fee) async {
    try {
      final testId = 'feetest_${DateTime.now().millisecondsSinceEpoch}';
      
      final testData = {
        'testId': testId,
        'feeType': feeType,
        'baseAmount': amount,
        'fee': fee,
        'testedAt': DateTime.now().toIso8601String(),
      };

      final result = await _databaseService.createPath(
        'feeTests/$testId',
        testData,
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to record fee test: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getFeeTestHistory() async {
    try {
      final result = await _databaseService.readPath('feeTests');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final tests = data.values
            .whereType<Map<String, dynamic>>()
            .toList();
        
        tests.sort((a, b) {
          final aDate = DateTime.tryParse(a['testedAt']?.toString() ?? '');
          final bDate = DateTime.tryParse(b['testedAt']?.toString() ?? '');
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

        return Result.success(tests);
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Failed to get fee test history: $e'));
    }
  }
}
