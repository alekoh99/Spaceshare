
/// Identity Verification Session Model
class IdentityVerificationSession {
  final String sessionId;
  final String userId;
  final String status; // 'pending', 'completed', 'failed', 'verified'
  final String verificationMethod; // 'stripe_identity', 'manual', 'selfie'
  final String? stripeIdentitySessionId;
  final String? documentType; // 'passport', 'drivers_license', 'id_card'
  final bool documentVerified;
  final bool selfieVerified;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;
  final Map<String, dynamic>? verificationData;

  IdentityVerificationSession({
    required this.sessionId,
    required this.userId,
    required this.status,
    required this.verificationMethod,
    this.stripeIdentitySessionId,
    this.documentType,
    required this.documentVerified,
    required this.selfieVerified,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
    this.verificationData,
  });

  factory IdentityVerificationSession.fromJson(
      Map<String, dynamic> json, String id) {
    return IdentityVerificationSession(
      sessionId: id,
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'pending',
      verificationMethod: json['verificationMethod'] ?? 'stripe_identity',
      stripeIdentitySessionId: json['stripeIdentitySessionId'],
      documentType: json['documentType'],
      documentVerified: json['documentVerified'] ?? false,
      selfieVerified: json['selfieVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      failureReason: json['failureReason'],
      verificationData: json['verificationData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'status': status,
      'verificationMethod': verificationMethod,
      'stripeIdentitySessionId': stripeIdentitySessionId,
      'documentType': documentType,
      'documentVerified': documentVerified,
      'selfieVerified': selfieVerified,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt != null ? completedAt!.toIso8601String() : null,
      'failureReason': failureReason,
      'verificationData': verificationData,
    };
  }
}

/// Trust Badge Model
class TrustBadge {
  final String badgeId;
  final String userId;
  final String type; // 'phone_verified', 'identity_verified', 'background_checked'
  final String title;
  final String description;
  final String icon; // Icon name or URL
  final DateTime earnedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  TrustBadge({
    required this.badgeId,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.earnedAt,
    this.expiresAt,
    required this.isActive,
    this.metadata,
  });

  factory TrustBadge.fromJson(Map<String, dynamic> json, String id) {
    return TrustBadge(
      badgeId: id,
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      isActive: json['isActive'] ?? true,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'icon': icon,
      'earnedAt': earnedAt.toIso8601String(),
      'expiresAt': expiresAt != null ? expiresAt!.toIso8601String() : null,
      'isActive': isActive,
      'metadata': metadata,
    };
  }
}
