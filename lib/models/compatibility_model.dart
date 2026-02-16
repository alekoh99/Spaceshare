/// Compatibility Dimension - represents a single dimension of compatibility
class CompatibilityDimension {
  final String id;
  final String name;
  final double weight; // 0.0 to 1.0
  final int score; // 0 to 100
  final String? description;

  CompatibilityDimension({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weight': weight,
      'score': score,
      'description': description,
    };
  }

  factory CompatibilityDimension.fromMap(Map<String, dynamic> map) {
    return CompatibilityDimension(
      id: map['id'] as String,
      name: map['name'] as String,
      weight: (map['weight'] as num).toDouble(),
      score: map['score'] as int,
      description: map['description'] as String?,
    );
  }
}

/// Compatibility Score - aggregated score between two users
class CompatibilityScore {
  final String userId1;
  final String userId2;
  final double overallScore; // 0 to 100
  final List<CompatibilityDimension> dimensions;
  final DateTime createdAt;
  final DateTime? expiresAt;

  CompatibilityScore({
    required this.userId1,
    required this.userId2,
    required this.overallScore,
    required this.dimensions,
    required this.createdAt,
    this.expiresAt,
  });

  /// Get dimension by ID
  CompatibilityDimension? getDimension(String dimensionId) {
    try {
      return dimensions.firstWhere((d) => d.id == dimensionId);
    } catch (e) {
      return null;
    }
  }

  /// Get total weights to validate they sum to 1.0
  double getTotalWeight() {
    return dimensions.fold(0.0, (sum, d) => sum + d.weight);
  }

  Map<String, dynamic> toJson() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'overallScore': overallScore,
      'dimensions': dimensions.map((d) => d.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory CompatibilityScore.fromJson(Map<String, dynamic> map) {
    return CompatibilityScore(
      userId1: map['userId1'] as String,
      userId2: map['userId2'] as String,
      overallScore: (map['overallScore'] as num).toDouble(),
      dimensions: (map['dimensions'] as List<dynamic>)
          .map((d) => CompatibilityDimension.fromMap(d as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : null,
    );
  }
}

/// User Compatibility Profile - individual user's compatibility attributes
class UserCompatibilityProfile {
  final String userId;
  final Map<String, int> dimensionScores; // dimensionId -> score (0-100)
  final DateTime lastUpdated;

  UserCompatibilityProfile({
    required this.userId,
    required this.dimensionScores,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'dimensionScores': dimensionScores,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserCompatibilityProfile.fromJson(Map<String, dynamic> map) {
    return UserCompatibilityProfile(
      userId: map['userId'] as String,
      dimensionScores: Map<String, int>.from(
        (map['dimensionScores'] as Map).cast<String, int>(),
      ),
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }
}
