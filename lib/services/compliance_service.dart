import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IComplianceService {
  Future<Result> checkUserCompliance(String userId);
  Future<Result> flagContentViolation({
    required String contentId,
    required String violationType,
    required String reason,
  });
  Future<Result> getPendingReviews();
  Future<Result> submitComplaint(
    String userId,
    String matchId,
    String reportedUserId,
    String category,
    String severity,
    String description,
    List<String> evidence,
  );
  Future<Result> getUserComplaints(String userId);
  Future<Result> getPendingComplaints();
  Future<Result> updateComplaintStatus(String complaintId, String status, String? resolutionNotes);
  Future<Result> getIncidents({String? userId, String? type});
  Future<Result> generateMonthlyReport();
  Future<Result> generateQuarterlyReport();
  Future<Result> getComplaint(String complaintId);
}

class ComplianceService implements IComplianceService {
  late final UnifiedDatabaseService _databaseService;

  ComplianceService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize ComplianceService: $e');
    }
  }

  @override
  Future<Result> checkUserCompliance(String userId) async {
    try {
      final userResult = await _databaseService.getProfile(userId);
      
      if (!userResult.isSuccess()) {
        return Result.failure(
          userResult.exception ?? Exception('User not found'),
        );
      }

      final user = userResult.data;
      
      // Perform compliance checks
      final complianceStatus = {
        'userId': userId,
        'isVerified': user?.verified ?? false,
        'backgroundCheckStatus': user?.backgroundCheckStatus ?? 'pending',
        'trustScore': user?.trustScore ?? 0,
        'suspensionStatus': user?.isSuspended ?? false,
        'lastCheckedAt': DateTime.now().toIso8601String(),
      };

      return Result.success(complianceStatus);
    } catch (e) {
      return Result.failure(Exception('Error checking compliance: $e'));
    }
  }

  @override
  Future<Result> flagContentViolation({
    required String contentId,
    required String violationType,
    required String reason,
  }) async {
    try {
      final violation = {
        'violationId': DateTime.now().millisecondsSinceEpoch.toString(),
        'contentId': contentId,
        'violationType': violationType,
        'reason': reason,
        'status': 'pending_review',
        'flaggedAt': DateTime.now().toIso8601String(),
      };

      final result = await _databaseService.createPath('violations/${violation['violationId']}', violation);
      
      if (result.isSuccess()) {
        return Result.success(null);
      } else {
        return Result.failure(result.exception ?? Exception('Failed to flag violation'));
      }
    } catch (e) {
      return Result.failure(Exception('Error flagging violation: $e'));
    }
  }

  @override
  Future<Result> getPendingReviews() async {
    try {
      // Fetch pending violations from database
      final result = await _databaseService.readPath('violations');
      
      if (result.isSuccess()) {
        final violations = (result.data as List?)
            ?.whereType<Map<String, dynamic>>()
            .where((v) => v['status'] == 'pending_review')
            .toList() ?? [];
        
        return Result.success(violations);
      } else {
        return Result.failure(
          result.exception ?? Exception('Failed to fetch pending reviews'),
        );
      }
    } catch (e) {
      return Result.failure(Exception('Error fetching reviews: $e'));
    }
  }

  @override
  Future<Result> submitComplaint(
    String userId,
    String matchId,
    String reportedUserId,
    String category,
    String severity,
    String description,
    List<String> evidence,
  ) async {
    try {
      final complaintId = 'complaint_${DateTime.now().millisecondsSinceEpoch}';
      final complaint = {
        'complaintId': complaintId,
        'userId': userId,
        'matchId': matchId,
        'reportedUserId': reportedUserId,
        'category': category,
        'severity': severity,
        'description': description,
        'evidence': evidence,
        'status': 'submitted',
        'submittedAt': DateTime.now().toIso8601String(),
      };
      
      await _databaseService.createPath('complaints/$complaintId', complaint);
      return Result.success(complaintId);
    } catch (e) {
      return Result.failure(Exception('Error submitting complaint: $e'));
    }
  }

  @override
  Future<Result> getUserComplaints(String userId) async {
    try {
      final result = await _databaseService.readPath('complaints');
      if (result.isSuccess() && result.data != null) {
        final complaintsData = Map<String, dynamic>.from(result.data!);
        final complaints = <Map<String, dynamic>>[];
        
        complaintsData.forEach((key, value) {
          final complaint = Map<String, dynamic>.from(value as Map);
          if (complaint['reporterId'] == userId || complaint['targetUserId'] == userId) {
            complaints.add(complaint);
          }
        });
        
        return Result.success(complaints);
      }
      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Error fetching user complaints: $e'));
    }
  }

  @override
  Future<Result> getPendingComplaints() async {
    try {
      final result = await _databaseService.readPath('complaints');
      if (result.isSuccess() && result.data != null) {
        final complaintsData = Map<String, dynamic>.from(result.data!);
        final pendingComplaints = <Map<String, dynamic>>[];
        
        complaintsData.forEach((key, value) {
          final complaint = Map<String, dynamic>.from(value as Map);
          if (complaint['status'] == 'open' || complaint['status'] == 'in_review') {
            pendingComplaints.add(complaint);
          }
        });
        
        return Result.success(pendingComplaints);
      }
      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Error fetching pending complaints: $e'));
    }
  }

  @override
  Future<Result> updateComplaintStatus(String complaintId, String status, String? resolutionNotes) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (resolutionNotes != null && resolutionNotes.isNotEmpty) {
        updateData['resolutionNotes'] = resolutionNotes;
      }
      
      if (status == 'resolved') {
        updateData['resolvedAt'] = DateTime.now().toIso8601String();
      }
      
      await _databaseService.updatePath('complaints/$complaintId', updateData);
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error updating complaint status: $e'));
    }
  }

  @override
  Future<Result> getIncidents({String? userId, String? type}) async {
    try {
      final result = await _databaseService.readPath('incidents');
      if (result.isSuccess() && result.data != null) {
        final incidentsData = Map<String, dynamic>.from(result.data!);
        final incidents = <Map<String, dynamic>>[];
        
        incidentsData.forEach((key, value) {
          final incident = Map<String, dynamic>.from(value as Map);
          
          bool matches = true;
          if (userId != null && incident['userId'] != userId) {
            matches = false;
          }
          if (type != null && incident['type'] != type) {
            matches = false;
          }
          
          if (matches) {
            incidents.add(incident);
          }
        });
        
        return Result.success(incidents);
      }
      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Error fetching incidents: $e'));
    }
  }

  @override
  Future<Result> generateMonthlyReport() async {
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final report = {
        'reportId': 'monthly_${now.year}_${now.month}',
        'period': 'monthly',
        'startDate': firstDay.toIso8601String(),
        'endDate': now.toIso8601String(),
        'generatedAt': DateTime.now().toIso8601String(),
        'totalComplaints': 0,
        'resolvedComplaints': 0,
        'pendingComplaints': 0,
      };
      return Result.success(report);
    } catch (e) {
      return Result.failure(Exception('Error generating monthly report: $e'));
    }
  }

  @override
  Future<Result> generateQuarterlyReport() async {
    try {
      final now = DateTime.now();
      final quarter = ((now.month - 1) ~/ 3) + 1;
      final report = {
        'reportId': 'quarterly_${now.year}_q$quarter',
        'period': 'quarterly',
        'quarter': quarter,
        'generatedAt': DateTime.now().toIso8601String(),
        'totalComplaints': 0,
        'resolvedComplaints': 0,
        'pendingComplaints': 0,
      };
      return Result.success(report);
    } catch (e) {
      return Result.failure(Exception('Error generating quarterly report: $e'));
    }
  }

  @override
  Future<Result> getComplaint(String complaintId) async {
    try {
      final result = await _databaseService.readPath('complaints/$complaintId');
      if (result.isSuccess() && result.data != null) {
        return Result.success(Map<String, dynamic>.from(result.data!));
      }
      return Result.failure(result.exception ?? Exception('Complaint not found'));
    } catch (e) {
      return Result.failure(Exception('Error fetching complaint: $e'));
    }
  }
}
