import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/compliance_model.dart';
import '../services/compliance_service.dart';
import '../utils/logger.dart';
import 'auth_controller.dart';

class ComplianceController extends GetxController {
  late IComplianceService _complianceService;

  IComplianceService get complianceService => _complianceService;

  @override
  void onInit() {
    super.onInit();
    try {
      _complianceService = Get.find<IComplianceService>();
      authController = Get.find<AuthController>();
    } catch (e) {
      debugPrint('Failed to resolve ComplianceController services: $e');
      rethrow;
    }
  }
  
  late AuthController authController;

  // State variables
  final complaints = RxList<DiscriminationComplaint>([]);
  final incidents = RxList<ComplianceIncident>([]);
  final auditReport = Rx<ComplianceAuditReport?>(null);
  
  final isLoadingComplaints = false.obs;
  final isLoadingIncidents = false.obs;
  final isGeneratingReport = false.obs;
  final isSubmittingComplaint = false.obs;
  
  final error = Rx<String?>(null);

  /// Submit a discrimination complaint
  Future<void> submitComplaint({
    required String matchId,
    required String reportedUserId,
    required String category,
    required String severity,
    required String description,
    List<String> evidence = const [],
  }) async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isSubmittingComplaint.value = true;
      error.value = null;

      await _complianceService.submitComplaint(
        authController.currentUserId.value!,
        matchId,
        reportedUserId,
        category,
        severity,
        description,
        evidence,
      );

      // Reload complaints
      await loadUserComplaints();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSubmittingComplaint.value = false;
    }
  }

  /// Load user's discrimination complaints
  Future<void> loadUserComplaints() async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isLoadingComplaints.value = true;
      final result = await _complianceService.getUserComplaints(authController.currentUserId.value!);
      if (result.isSuccess()) {
        final userComplaints = (result.getOrNull() as List<dynamic>?)?.cast<DiscriminationComplaint>() ?? <DiscriminationComplaint>[];
        complaints.value = userComplaints;
      } else {
        complaints.value = [];
      }
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingComplaints.value = false;
    }
  }

  /// Load pending complaints (admin view)
  Future<void> loadPendingComplaints() async {
    try {
      isLoadingComplaints.value = true;
      final result = await _complianceService.getPendingComplaints();
      if (result.isSuccess()) {
        final pending = (result.getOrNull() as List<dynamic>?)?.cast<DiscriminationComplaint>() ?? <DiscriminationComplaint>[];
        complaints.value = pending;
      } else {
        complaints.value = [];
      }
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingComplaints.value = false;
    }
  }

  /// Update complaint status (admin action)
  Future<void> updateComplaintStatus(
    String complaintId,
    String newStatus,
    String? resolutionNotes,
  ) async {
    try {
      await _complianceService.updateComplaintStatus(
        complaintId,
        newStatus,
        resolutionNotes,
      );
      await loadPendingComplaints();
    } catch (e) {
      error.value = e.toString();
    }
  }

  /// Load compliance incidents
  Future<void> loadIncidents({String? userId, String? type}) async {
    try {
      isLoadingIncidents.value = true;
      final result = await _complianceService.getIncidents(
        userId: userId,
        type: type,
      );
      
      if (result.isSuccess()) {
        final incidentsList = (result.getOrNull() as List<dynamic>?)?.map((item) => ComplianceIncident.fromJson(item as Map<String, dynamic>)).toList() ?? <ComplianceIncident>[];
        incidents.value = incidentsList;
      } else {
        incidents.value = [];
      }
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingIncidents.value = false;
    }
  }

  /// Generate monthly compliance audit report
  Future<void> generateMonthlyReport() async {
    try {
      isGeneratingReport.value = true;
      final result = await _complianceService.generateMonthlyReport();
      if (result.isSuccess()) {
        final report = result.getOrNull() as ComplianceAuditReport?;
        auditReport.value = report;
      }
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isGeneratingReport.value = false;
    }
  }

  /// Generate quarterly compliance audit report
  Future<void> generateQuarterlyReport() async {
    try {
      isGeneratingReport.value = true;
      final result = await _complianceService.generateQuarterlyReport();
      if (result.isSuccess()) {
        final report = result.getOrNull() as ComplianceAuditReport?;
        auditReport.value = report;
      }
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isGeneratingReport.value = false;
    }
  }

  /// Get complaint details
  Future<DiscriminationComplaint?> getComplaintDetails(
    String complaintId,
  ) async {
    try {
      final result = await _complianceService.getComplaint(complaintId);
      if (result.isSuccess()) {
        return result.getOrNull() as DiscriminationComplaint?;
      }
      return null;
    } catch (e) {
      error.value = e.toString();
      return null;
    }
  }

  @override
  void onClose() {
    AppLogger.info('ComplianceController', 'Disposing controller resources');
    complaints.clear();
    incidents.clear();
    super.onClose();
  }
}
