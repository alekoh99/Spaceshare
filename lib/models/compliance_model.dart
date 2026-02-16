
/// Discrimination complaint submission model
class DiscriminationComplaint {
  final String complaintId;
  final String userId;
  final String matchId;
  final String reportedUserId;
  final String category; // 'race', 'religion', 'disability', 'gender', 'familial_status', 'national_origin', 'source_of_income'
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String description;
  final List<String> evidence; // URLs to screenshots or evidence
  final String status; // 'submitted', 'under_review', 'resolved', 'dismissed'
  final DateTime submittedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final String? adminNotes;

  DiscriminationComplaint({
    required this.complaintId,
    required this.userId,
    required this.matchId,
    required this.reportedUserId,
    required this.category,
    required this.severity,
    required this.description,
    this.evidence = const [],
    this.status = 'submitted',
    required this.submittedAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.adminNotes,
  });

  factory DiscriminationComplaint.fromJson(Map<String, dynamic> json) {
    return DiscriminationComplaint(
      complaintId: json['complaintId'] as String,
      userId: json['userId'] as String,
      matchId: json['matchId'] as String,
      reportedUserId: json['reportedUserId'] as String,
      category: json['category'] as String,
      severity: json['severity'] as String,
      description: json['description'] as String,
      evidence: List<String>.from(json['evidence'] as List? ?? []),
      status: json['status'] as String? ?? 'submitted',
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolutionNotes: json['resolutionNotes'] as String?,
      adminNotes: json['adminNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complaintId': complaintId,
      'userId': userId,
      'matchId': matchId,
      'reportedUserId': reportedUserId,
      'category': category,
      'severity': severity,
      'description': description,
      'evidence': evidence,
      'status': status,
      'submittedAt': submittedAt.toIso8601String(),
      'resolvedAt': resolvedAt != null ? resolvedAt!.toIso8601String() : null,
      'resolutionNotes': resolutionNotes,
      'adminNotes': adminNotes,
    };
  }
}

/// Compliance incident log for Fair Housing auditing
class ComplianceIncident {
  final String incidentId;
  final String userId;
  final String? matchId;
  final String type; // 'discrimination_complaint', 'algorithm_bias', 'system_error', 'user_report'
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String description;
  final Map<String, dynamic> details;
  final String status; // 'logged', 'investigating', 'resolved'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final bool requiresFollowUp;

  ComplianceIncident({
    required this.incidentId,
    required this.userId,
    this.matchId,
    required this.type,
    required this.severity,
    required this.description,
    this.details = const {},
    this.status = 'logged',
    required this.createdAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.requiresFollowUp = false,
  });

  // Getter for compatibility with 'id' references
  String get id => incidentId;

  factory ComplianceIncident.fromJson(Map<String, dynamic> json) {
    return ComplianceIncident(
      incidentId: json['incidentId'] as String,
      userId: json['userId'] as String,
      matchId: json['matchId'] as String?,
      type: json['type'] as String,
      severity: json['severity'] as String,
      description: json['description'] as String,
      details: json['details'] as Map<String, dynamic>? ?? {},
      status: json['status'] as String? ?? 'logged',
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolutionNotes: json['resolutionNotes'] as String?,
      requiresFollowUp: json['requiresFollowUp'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'incidentId': incidentId,
      'userId': userId,
      'matchId': matchId,
      'type': type,
      'severity': severity,
      'description': description,
      'details': details,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt != null ? resolvedAt!.toIso8601String() : null,
      'resolutionNotes': resolutionNotes,
      'requiresFollowUp': requiresFollowUp,
    };
  }
}

/// Fair Housing compliance audit report
class ComplianceAuditReport {
  final String reportId;
  final DateTime generatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalComplaintsSubmitted;
  final int totalIncidentsLogged;
  final Map<String, int> complaintsByCategory; // category -> count
  final Map<String, int> incidentsBySeverity; // severity -> count
  final double averageResolutionDays;
  final List<String> flaggedUsers; // Users with multiple complaints
  final String status; // 'draft', 'completed', 'reviewed'

  ComplianceAuditReport({
    required this.reportId,
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.totalComplaintsSubmitted,
    required this.totalIncidentsLogged,
    required this.complaintsByCategory,
    required this.incidentsBySeverity,
    required this.averageResolutionDays,
    required this.flaggedUsers,
    this.status = 'draft',
  });

  factory ComplianceAuditReport.fromJson(Map<String, dynamic> json) {
    return ComplianceAuditReport(
      reportId: json['reportId'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      totalComplaintsSubmitted: json['totalComplaintsSubmitted'] as int,
      totalIncidentsLogged: json['totalIncidentsLogged'] as int,
      complaintsByCategory:
          Map<String, int>.from(json['complaintsByCategory'] as Map),
      incidentsBySeverity:
          Map<String, int>.from(json['incidentsBySeverity'] as Map),
      averageResolutionDays:
          (json['averageResolutionDays'] as num).toDouble(),
      flaggedUsers:
          List<String>.from(json['flaggedUsers'] as List? ?? []),
      status: json['status'] as String? ?? 'draft',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'generatedAt': generatedAt.toIso8601String(),
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalComplaintsSubmitted': totalComplaintsSubmitted,
      'totalIncidentsLogged': totalIncidentsLogged,
      'complaintsByCategory': complaintsByCategory,
      'incidentsBySeverity': incidentsBySeverity,
      'averageResolutionDays': averageResolutionDays,
      'flaggedUsers': flaggedUsers,
      'status': status,
    };
  }
}
