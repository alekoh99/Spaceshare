/// Additional Supporting Models
library;

// Onboarding/Questionnaire Response
class CompatibilityQuestions {
  static const List<String> questions = [
    "How would you describe your living space cleanliness?",
    "What's your typical sleep schedule?",
    "How often do you have people over?",
    "What's your tolerance for noise?",
    "How important is financial responsibility to you?",
  ];

  static const Map<String, List<String>> answerOptions = {
    'cleanliness': ['Very Messy', 'Messy', 'Average', 'Clean', 'Very Clean'],
    'sleepSchedule': ['Early Bird (Before 10 PM)', 'Normal', 'Night Owl (After 11 PM)'],
    'socialFrequency': ['Very Introverted', 'Introverted', 'Moderate', 'Social', 'Very Social'],
    'noiseTolerance': ['Need Complete Silence', 'Prefer Quiet', 'Moderate', 'Okay with Noise', 'No Problem with Noise'],
    'financialReliability': ['Often Late', 'Sometimes Late', 'Usually On Time', 'Always On Time'],
  };
}

/// Listing Model - Apartment listings (potential future feature)
class Listing {
  final String listingId;
  final String landlordId;
  final String address;
  final String city;
  final String state;
  final List<String> neighborhoods;
  final double rent;
  final int bedrooms;
  final int bathrooms;
  final String description;
  final List<String> amenities; // 'wifi', 'laundry', 'parking', etc.
  final List<String> imageUrls;
  final DateTime createdAt;
  final bool isActive;

  Listing({
    required this.listingId,
    required this.landlordId,
    required this.address,
    required this.city,
    required this.state,
    required this.neighborhoods,
    required this.rent,
    required this.bedrooms,
    required this.bathrooms,
    required this.description,
    required this.amenities,
    required this.imageUrls,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'listingId': listingId,
      'landlordId': landlordId,
      'address': address,
      'city': city,
      'state': state,
      'neighborhoods': neighborhoods,
      'rent': rent,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'description': description,
      'amenities': amenities,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}

/// Report Model - User reports for safety and compliance
class Report {
  final String reportId;
  final String reportedByUserId;
  final String reportedUserId;
  final String category; // 'harassment', 'fraud', 'safety', 'inappropriate'
  final String description;
  final DateTime createdAt;
  final String status; // 'open', 'investigating', 'resolved', 'dismissed'
  final String? resolution;
  final String? attachmentUrls;

  Report({
    required this.reportId,
    required this.reportedByUserId,
    required this.reportedUserId,
    required this.category,
    required this.description,
    required this.createdAt,
    this.status = 'open',
    this.resolution,
    this.attachmentUrls,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'reportedByUserId': reportedByUserId,
      'reportedUserId': reportedUserId,
      'category': category,
      'description': description,
      'createdAt': createdAt,
      'status': status,
      'resolution': resolution,
      'attachmentUrls': attachmentUrls,
    };
  }
}

/// Notification Model
class Notification {
  final String notificationId;
  final String userId;
  final String type; // 'match', 'message', 'payment', 'system'
  final String title;
  final String body;
  final String? actionUrl;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  Notification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.actionUrl,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
  });

  // Getter for compatibility with 'id' references
  String get id => notificationId;

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'actionUrl': actionUrl,
      'createdAt': createdAt,
      'isRead': isRead,
      'readAt': readAt,
    };
  }

  // copyWith method for creating modified copies
  Notification copyWith({
    String? notificationId,
    String? userId,
    String? type,
    String? title,
    String? body,
    String? actionUrl,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
  }) {
    return Notification(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      actionUrl: actionUrl ?? this.actionUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }
}
