class NotificationPreferences {
  final String userId;
  final Map<String, bool> preferences;
  final String messageFrequency;
  final String matchFrequency;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final DateTime updatedAt;

  NotificationPreferences({
    required this.userId,
    required this.preferences,
    this.messageFrequency = 'instant',
    this.matchFrequency = 'instant',
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.updatedAt,
  });

  factory NotificationPreferences.empty() {
    return NotificationPreferences(
      userId: '',
      preferences: {
        'matchNotifications': true,
        'messageNotifications': true,
        'paymentNotifications': true,
        'systemNotifications': true,
        'emailNotifications': false,
        'pushNotifications': true,
        'smsNotifications': false,
      },
      messageFrequency: 'instant',
      matchFrequency: 'instant',
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'preferences': preferences,
      'messageFrequency': messageFrequency,
      'matchFrequency': matchFrequency,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      userId: json['userId'] as String? ?? '',
      preferences: Map<String, bool>.from(
        (json['preferences'] as Map<String, dynamic>?) ?? {},
      ),
      messageFrequency: json['messageFrequency'] as String? ?? 'instant',
      matchFrequency: json['matchFrequency'] as String? ?? 'instant',
      quietHoursStart: json['quietHoursStart'] as String?,
      quietHoursEnd: json['quietHoursEnd'] as String?,
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'] as String)
          : (json['updatedAt'] is DateTime
              ? json['updatedAt'] as DateTime
              : DateTime.now()),
    );
  }

  NotificationPreferences copyWith({
    String? userId,
    Map<String, bool>? preferences,
    String? messageFrequency,
    String? matchFrequency,
    String? quietHoursStart,
    String? quietHoursEnd,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      userId: userId ?? this.userId,
      preferences: preferences ?? this.preferences,
      messageFrequency: messageFrequency ?? this.messageFrequency,
      matchFrequency: matchFrequency ?? this.matchFrequency,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
