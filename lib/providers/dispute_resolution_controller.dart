import 'package:get/get.dart';
import '../services/dispute_resolution_service.dart';
import '../utils/logger.dart';
import 'auth_controller.dart';

class DisputeResolutionController extends GetxController {
  late IDisputeResolutionService _disputeService;
  late AuthController _authController;

  final openDisputes = RxList<Map<String, dynamic>>([]);
  final resolvedDisputes = RxList<Map<String, dynamic>>([]);
  final currentDispute = Rx<Map<String, dynamic>?>({});
  final isLoadingDisputes = false.obs;
  final isCreatingDispute = false.obs;
  final isSubmittingEvidence = false.obs;
  final error = Rx<String?>(null);
  final successMessage = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    try {
      _disputeService = Get.find<IDisputeResolutionService>();
      _authController = Get.find<AuthController>();
    } catch (e) {
      AppLogger.error('DisputeResolutionController', 'Failed to resolve services', e);
      rethrow;
    }
  }

  Future<String?> createDispute({
    required String paymentId,
    required String reason,
  }) async {
    try {
      if (_authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return null;
      }

      isCreatingDispute.value = true;
      final result = await _disputeService.createDispute(
        paymentId,
        _authController.currentUserId.value!,
        reason,
      );

      if (result.isSuccess()) {
        final disputeId = result.getOrNull();
        successMessage.value = 'Dispute created successfully';
        await loadDisputes();
        return disputeId;
      } else {
        error.value = 'Failed to create dispute';
        return null;
      }
    } catch (e) {
      AppLogger.error('DisputeResolutionController', 'Error creating dispute', e);
      error.value = e.toString();
      return null;
    } finally {
      isCreatingDispute.value = false;
    }
  }

  Future<void> loadDispute(String disputeId) async {
    try {
      final result = await _disputeService.getDispute(disputeId);

      if (result.isSuccess()) {
        final dispute = result.getOrNull();
        if (dispute != null) {
          currentDispute.value = dispute;
          error.value = null;
        } else {
          error.value = 'Dispute not found';
        }
      } else {
        error.value = 'Failed to load dispute';
      }
    } catch (e) {
      AppLogger.error('DisputeResolutionController', 'Error loading dispute', e);
      error.value = e.toString();
    }
  }

  Future<void> loadDisputes() async {
    try {
      if (_authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isLoadingDisputes.value = true;
      // Note: This is a simplified implementation. In production, you'd need a
      // getDisputesByUser method in the service
      openDisputes.clear();
      resolvedDisputes.clear();
      error.value = null;
    } catch (e) {
      AppLogger.error('DisputeResolutionController', 'Error loading disputes', e);
      error.value = e.toString();
    } finally {
      isLoadingDisputes.value = false;
    }
  }

  Future<void> submitEvidence(String disputeId, String evidence) async {
    try {
      if (_authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isSubmittingEvidence.value = true;
      final result = await _disputeService.submitEvidence(
        disputeId,
        _authController.currentUserId.value!,
        evidence,
      );

      if (result.isSuccess()) {
        successMessage.value = 'Evidence submitted successfully';
        await loadDispute(disputeId);
        error.value = null;
      } else {
        error.value = 'Failed to submit evidence';
      }
    } catch (e) {
      AppLogger.error('DisputeResolutionController', 'Error submitting evidence', e);
      error.value = e.toString();
    } finally {
      isSubmittingEvidence.value = false;
    }
  }

  Future<void> resolveDispute(String disputeId, String resolution) async {
    try {
      if (_authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      final result = await _disputeService.resolveDispute(
        disputeId,
        resolution,
        _authController.currentUserId.value!,
      );

      if (result.isSuccess()) {
        successMessage.value = 'Dispute resolved successfully';
        await loadDispute(disputeId);
        error.value = null;
      } else {
        error.value = 'Failed to resolve dispute';
      }
    } catch (e) {
      AppLogger.error('DisputeResolutionController', 'Error resolving dispute', e);
      error.value = e.toString();
    }
  }

  String getDisputeStatus(Map<String, dynamic> dispute) {
    return dispute['status'] as String? ?? 'Unknown';
  }

  String getDisputeReason(Map<String, dynamic> dispute) {
    return dispute['reason'] as String? ?? 'No reason provided';
  }

  List<Map<String, dynamic>> getEvidence(Map<String, dynamic> dispute) {
    final evidence = dispute['evidence'] as List?;
    return evidence?.cast<Map<String, dynamic>>() ?? [];
  }
}
