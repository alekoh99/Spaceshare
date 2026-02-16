
/// Review Model - Roommate reviews and ratings
class RoommateReview {
  final String reviewId;
  final String reviewerId; // Person leaving the review
  final String revieweeId; // Person being reviewed
  final String matchId; // Associated match ID
  final double rating; // 1-5 stars
  final String title;
  final String comment;
  
  // Detailed Ratings
  final double cleanlinessRating;
  final double noiseRating;
  final double respectRating;
  final double communicationRating;
  final double reliabilityRating;
  
  // Aspects
  final List<String> positiveAspects; // ['clean', 'quiet', 'friendly', 'respectful', etc.]
  final List<String> negativeAspects; // ['messy', 'loud', 'inconsiderate', etc.]
  
  // Verification
  final bool verified; // Verified that they actually lived together
  final String? liveTogetherPeriod; // e.g., "6 months", "1 year"
  final DateTime? livingEndDate;
  
  // Status
  final String status; // 'pending', 'approved', 'rejected', 'published'
  final bool isAnonymous;
  final bool isPrivate; // Only visible to reviewed user
  
  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int helpfulCount; // Number of people who found this helpful
  final int unhelpfulCount;
  final List<String> flaggedBy; // Users who reported as inappropriate
  final String? flagReason;

  RoommateReview({
    required this.reviewId,
    required this.reviewerId,
    required this.revieweeId,
    required this.matchId,
    required this.rating,
    required this.title,
    required this.comment,
    required this.cleanlinessRating,
    required this.noiseRating,
    required this.respectRating,
    required this.communicationRating,
    required this.reliabilityRating,
    required this.positiveAspects,
    required this.negativeAspects,
    this.verified = false,
    this.liveTogetherPeriod,
    this.livingEndDate,
    this.status = 'pending',
    this.isAnonymous = false,
    this.isPrivate = false,
    required this.createdAt,
    this.updatedAt,
    this.helpfulCount = 0,
    this.unhelpfulCount = 0,
    this.flaggedBy = const [],
    this.flagReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'matchId': matchId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'cleanlinessRating': cleanlinessRating,
      'noiseRating': noiseRating,
      'respectRating': respectRating,
      'communicationRating': communicationRating,
      'reliabilityRating': reliabilityRating,
      'positiveAspects': positiveAspects,
      'negativeAspects': negativeAspects,
      'verified': verified,
      'liveTogetherPeriod': liveTogetherPeriod,
      'livingEndDate': livingEndDate != null ? livingEndDate!.toIso8601String() : null,
      'status': status,
      'isAnonymous': isAnonymous,
      'isPrivate': isPrivate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt != null ? updatedAt!.toIso8601String() : null,
      'helpfulCount': helpfulCount,
      'unhelpfulCount': unhelpfulCount,
      'flaggedBy': flaggedBy,
      'flagReason': flagReason,
    };
  }

  factory RoommateReview.fromJson(Map<String, dynamic> json) {
    return RoommateReview(
      reviewId: json['reviewId'] as String,
      reviewerId: json['reviewerId'] as String,
      revieweeId: json['revieweeId'] as String,
      matchId: json['matchId'] as String,
      rating: (json['rating'] as num).toDouble(),
      title: json['title'] as String,
      comment: json['comment'] as String,
      cleanlinessRating: (json['cleanlinessRating'] as num).toDouble(),
      noiseRating: (json['noiseRating'] as num).toDouble(),
      respectRating: (json['respectRating'] as num).toDouble(),
      communicationRating: (json['communicationRating'] as num).toDouble(),
      reliabilityRating: (json['reliabilityRating'] as num).toDouble(),
      positiveAspects: List<String>.from(json['positiveAspects'] as List? ?? []),
      negativeAspects: List<String>.from(json['negativeAspects'] as List? ?? []),
      verified: json['verified'] as bool? ?? false,
      liveTogetherPeriod: json['liveTogetherPeriod'] as String?,
      livingEndDate: json['livingEndDate'] != null ? DateTime.parse(json['livingEndDate'] as String) : null,
      status: json['status'] as String? ?? 'pending',
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isPrivate: json['isPrivate'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      helpfulCount: json['helpfulCount'] as int? ?? 0,
      unhelpfulCount: json['unhelpfulCount'] as int? ?? 0,
      flaggedBy: List<String>.from(json['flaggedBy'] as List? ?? []),
      flagReason: json['flagReason'] as String?,
    );
  }
}
