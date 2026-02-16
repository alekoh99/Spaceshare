
/// Match Model - Represents a potential or confirmed roommate match
class Match {
  final String matchId;
  final String user1Id;
  final String user2Id;
  final double compatibilityScore; // 0-100
  final String status; // 'pending', 'accepted', 'rejected', 'archived', 'matched'
  final DateTime createdAt;
  final DateTime? matchedAt; // When both users accepted
  final DateTime? rejectedAt;
  final DateTime? expiredAt; // Matches expire after 30 days if not acted on
  
  // Optional: Associated listing if match is for a specific apartment
  final String? sharedListingId;
  final String? sharedListingAddress;
  final double? sharedRent;
  
  // Scoring breakdown for transparency
  final double cleanlinessScore;
  final double sleepScheduleScore;
  final double socialFrequencyScore;
  final double noiseToleranceScore;
  final double financialReliabilityScore;
  
  // Interaction tracking
  final int messageCount;
  final DateTime? lastMessageAt;

  Match({
    required this.matchId,
    required this.user1Id,
    required this.user2Id,
    required this.compatibilityScore,
    required this.status,
    required this.createdAt,
    this.matchedAt,
    this.rejectedAt,
    this.expiredAt,
    this.sharedListingId,
    this.sharedListingAddress,
    this.sharedRent,
    required this.cleanlinessScore,
    required this.sleepScheduleScore,
    required this.socialFrequencyScore,
    required this.noiseToleranceScore,
    required this.financialReliabilityScore,
    this.messageCount = 0,
    this.lastMessageAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'compatibilityScore': compatibilityScore,
      'status': status,
      'createdAt': createdAt,
      'matchedAt': matchedAt,
      'rejectedAt': rejectedAt,
      'expiredAt': expiredAt,
      'sharedListingId': sharedListingId,
      'sharedListingAddress': sharedListingAddress,
      'sharedRent': sharedRent,
      'scoreBreakdown': {
        'cleanliness': cleanlinessScore,
        'sleepSchedule': sleepScheduleScore,
        'socialFrequency': socialFrequencyScore,
        'noiseTolerance': noiseToleranceScore,
        'financialReliability': financialReliabilityScore,
      },
      'messageCount': messageCount,
      'lastMessageAt': lastMessageAt,
    };
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    final scoreBreakdown = json['scoreBreakdown'] as Map<String, dynamic>? ?? {};
    return Match(
      matchId: json['matchId'] as String,
      user1Id: json['user1Id'] as String,
      user2Id: json['user2Id'] as String,
      compatibilityScore: (json['compatibilityScore'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      matchedAt: json['matchedAt'] != null
          ? DateTime.parse(json['matchedAt'] as String)
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'] as String)
          : null,
      expiredAt: json['expiredAt'] != null
          ? DateTime.parse(json['expiredAt'] as String)
          : null,
      sharedListingId: json['sharedListingId'] as String?,
      sharedListingAddress: json['sharedListingAddress'] as String?,
      sharedRent: (json['sharedRent'] as num?)?.toDouble(),
      cleanlinessScore: (scoreBreakdown['cleanliness'] as num?)?.toDouble() ?? 0,
      sleepScheduleScore:
          (scoreBreakdown['sleepSchedule'] as num?)?.toDouble() ?? 0,
      socialFrequencyScore:
          (scoreBreakdown['socialFrequency'] as num?)?.toDouble() ?? 0,
      noiseToleranceScore:
          (scoreBreakdown['noiseTolerance'] as num?)?.toDouble() ?? 0,
      financialReliabilityScore:
          (scoreBreakdown['financialReliability'] as num?)?.toDouble() ?? 0,
      messageCount: json['messageCount'] as int? ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
    );
  }

  Match copyWith({
    String? status,
    DateTime? matchedAt,
    DateTime? rejectedAt,
    DateTime? expiredAt,
    int? messageCount,
    DateTime? lastMessageAt,
  }) {
    return Match(
      matchId: matchId,
      user1Id: user1Id,
      user2Id: user2Id,
      compatibilityScore: compatibilityScore,
      status: status ?? this.status,
      createdAt: createdAt,
      matchedAt: matchedAt ?? this.matchedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      expiredAt: expiredAt ?? this.expiredAt,
      sharedListingId: sharedListingId,
      sharedListingAddress: sharedListingAddress,
      sharedRent: sharedRent,
      cleanlinessScore: cleanlinessScore,
      sleepScheduleScore: sleepScheduleScore,
      socialFrequencyScore: socialFrequencyScore,
      noiseToleranceScore: noiseToleranceScore,
      financialReliabilityScore: financialReliabilityScore,
      messageCount: messageCount ?? this.messageCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}
