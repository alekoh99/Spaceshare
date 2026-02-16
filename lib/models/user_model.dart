
/// User Profile Model
class UserProfile {
  final String userId;
  final String name;
  final int age;
  final String? avatar; // URL to profile image
  final String bio;
  final String phone;
  final bool phoneVerified;
  final String? email;
  final bool emailVerified;

  // Location & Preferences
  final String city;
  final String state;
  final List<String> neighborhoods; // Preferred neighborhoods
  final DateTime moveInDate;
  final double budgetMin;
  final double budgetMax;
  final String? roommatePrefGender; // 'M', 'F', 'Any', null for unspecified

  // Verification Status
  final bool verified; // Stripe Identity verified
  final String? stripeConnectId; // Stripe Connect Account ID
  final String? backgroundCheckStatus; // 'pending', 'approved', 'rejected', null
  final DateTime? backgroundCheckDate;
  
  // Trust & Safety
  final int trustScore; // 0-100 calculated from verifications
  final List<String> trustBadgeIds; // IDs of active trust badges
  final DateTime? identityVerifiedAt;
  final bool identityDocumentSelfieVerified; // Selfie + ID document verified

  // Compatibility Scores (1-10 scale)
  final int cleanliness; // 1=very messy, 10=very clean
  final String sleepSchedule; // 'early' (before 10pm), 'normal', 'night' (after 11pm)
  final int socialFrequency; // 1=very introverted, 10=very social
  final int noiseTolerance; // 1=needs silence, 10=fine with noise
  final int financialReliability; // 1=often late, 10=always on time
  
  // Extended Compatibility Dimensions
  final bool? hasPets; // Whether user has pets
  final int? petTolerance; // 1-10 scale, comfort with others' pets
  final int? guestPolicy; // 1-10 scale, comfort with guests
  final int? privacyNeed; // 1-10 scale, need for privacy
  final int? kitchenHabits; // 1-10 scale, cleanliness in shared kitchen

  // Account Status
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isActive;
  final bool isSuspended;
  final String? suspensionReason;

  UserProfile({
    required this.userId,
    required this.name,
    required this.age,
    this.avatar,
    required this.bio,
    required this.phone,
    this.phoneVerified = false,
    this.email,
    this.emailVerified = false,
    required this.city,
    required this.state,
    required this.neighborhoods,
    required this.moveInDate,
    required this.budgetMin,
    required this.budgetMax,
    this.roommatePrefGender,
    this.verified = false,
    this.stripeConnectId,
    this.backgroundCheckStatus,
    this.backgroundCheckDate,
    this.trustScore = 50,
    this.trustBadgeIds = const [],
    this.identityVerifiedAt,
    this.identityDocumentSelfieVerified = false,
    required this.cleanliness,
    required this.sleepSchedule,
    required this.socialFrequency,
    required this.noiseTolerance,
    required this.financialReliability,
    this.hasPets,
    this.petTolerance,
    this.guestPolicy,
    this.privacyNeed,
    this.kitchenHabits,
    required this.createdAt,
    required this.lastActiveAt,
    this.isActive = true,
    this.isSuspended = false,
    this.suspensionReason,
  });

  /// Convert to JSON/HTTP format (uses ISO8601 strings for dates to avoid serialization issues)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'age': age,
      'avatar': avatar,
      'bio': bio,
      'phone': phone,
      'phoneVerified': phoneVerified,
      'email': email,
      'emailVerified': emailVerified,
      'city': city,
      'state': state,
      'neighborhoods': neighborhoods,
      'moveInDate': moveInDate.toIso8601String(),
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'roommatePrefGender': roommatePrefGender,
      'verified': verified,
      'stripeConnectId': stripeConnectId,
      'backgroundCheckStatus': backgroundCheckStatus,
      'backgroundCheckDate': backgroundCheckDate?.toIso8601String(),
      'trustScore': trustScore,
      'trustBadgeIds': trustBadgeIds,
      'identityVerifiedAt': identityVerifiedAt?.toIso8601String(),
      'identityDocumentSelfieVerified': identityDocumentSelfieVerified,
      // Flat compatibility structure for easier queries
      'cleanliness': cleanliness,
      'sleepSchedule': sleepSchedule,
      'socialFrequency': socialFrequency,
      'noiseTolerance': noiseTolerance,
      'financialReliability': financialReliability,
      'hasPets': hasPets,
      'petTolerance': petTolerance,
      'guestPolicy': guestPolicy,
      'privacyNeed': privacyNeed,
      'kitchenHabits': kitchenHabits,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'isActive': isActive,
      'isSuspended': isSuspended,
      'suspensionReason': suspensionReason,
    };
  }

  /// Convert to Firestore format (uses Firestore Timestamps)
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'age': age,
      'avatar': avatar,
      'bio': bio,
      'phone': phone,
      'phoneVerified': phoneVerified,
      'email': email,
      'emailVerified': emailVerified,
      'city': city,
      'state': state,
      'neighborhoods': neighborhoods,
      'moveInDate': moveInDate.toIso8601String(),
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'roommatePrefGender': roommatePrefGender,
      'verified': verified,
      'stripeConnectId': stripeConnectId,
      'backgroundCheckStatus': backgroundCheckStatus,
      'backgroundCheckDate': backgroundCheckDate != null
          ? backgroundCheckDate!.toIso8601String()
          : null,
      'trustScore': trustScore,
      'trustBadgeIds': trustBadgeIds,
      'identityVerifiedAt': identityVerifiedAt?.toIso8601String(),
      'identityDocumentSelfieVerified': identityDocumentSelfieVerified,
      // Flat compatibility structure for easier queries
      'cleanliness': cleanliness,
      'sleepSchedule': sleepSchedule,
      'socialFrequency': socialFrequency,
      'noiseTolerance': noiseTolerance,
      'financialReliability': financialReliability,
      'hasPets': hasPets,
      'petTolerance': petTolerance,
      'guestPolicy': guestPolicy,
      'privacyNeed': privacyNeed,
      'kitchenHabits': kitchenHabits,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'isActive': isActive,
      'isSuspended': isSuspended,
      'suspensionReason': suspensionReason,
    };
  }

  /// Create an empty/default UserProfile
  factory UserProfile.empty() {
    final now = DateTime.now();
    return UserProfile(
      userId: '',
      name: '',
      age: 0,
      bio: '',
      phone: '',
      city: '',
      state: '',
      neighborhoods: [],
      moveInDate: now,
      budgetMin: 0,
      budgetMax: 0,
      cleanliness: 5,
      sleepSchedule: 'normal',
      socialFrequency: 5,
      noiseTolerance: 5,
      financialReliability: 5,
      createdAt: now,
      lastActiveAt: now,
    );
  }

  /// Create from Firestore Document
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    try {
      // Support both flat and nested compatibility structures
      final compatibility = json['compatibility'] as Map<String, dynamic>? ?? {};
      
      // Safe parsing for timestamps
      DateTime parseTimestamp(dynamic value) {
        if (value == null) return DateTime.now();
        if (value is String) return DateTime.parse(value);
        if (value is DateTime) return value;
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (_) {
            return DateTime.now();
          }
        }
        return DateTime.now();
      }
      
      // Safe parsing for string (handles null gracefully)
      String parseString(dynamic value, String defaultValue) {
        if (value == null) return defaultValue;
        return value.toString();
      }
      
      // Helper to get compatibility value from either flat or nested structure
      int getIntCompat(String key, int defaultValue) {
        // Try flat structure first
        if (json.containsKey(key)) {
          return (json[key] as num?)?.toInt() ?? defaultValue;
        }
        // Fall back to nested structure
        return (compatibility[key] as num?)?.toInt() ?? defaultValue;
      }
      
      String getStringCompat(String key, String defaultValue) {
        // Try flat structure first
        if (json.containsKey(key)) {
          return parseString(json[key], defaultValue);
        }
        // Fall back to nested structure
        return parseString(compatibility[key], defaultValue);
      }
      
      bool? getBoolCompat(String key) {
        // Try flat structure first
        if (json.containsKey(key)) {
          return json[key] as bool?;
        }
        // Fall back to nested structure
        return compatibility[key] as bool?;
      }
      
      final userId = json['userId'] as String? ?? 
                     json['_id'] as String? ?? 
                     json['user_id'] as String?;
      if (userId == null || userId.isEmpty) {
        throw FormatException('UserProfile must have a valid userId field');
      }
      
      return UserProfile(
        userId: userId,
        name: json['name'] as String? ?? 'User',
        age: json['age'] as int? ?? 0,
        avatar: json['avatar'] as String?,
        bio: json['bio'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        phoneVerified: json['phoneVerified'] as bool? ?? false,
        email: json['email'] as String?,
        emailVerified: json['emailVerified'] as bool? ?? false,
        city: json['city'] as String? ?? 'Unknown',
        state: json['state'] as String? ?? 'Unknown',
        neighborhoods: List<String>.from(json['neighborhoods'] as List? ?? []),
        moveInDate: parseTimestamp(json['moveInDate']),
        budgetMin: (json['budgetMin'] as num?)?.toDouble() ?? 0.0,
        budgetMax: (json['budgetMax'] as num?)?.toDouble() ?? 10000.0,
        roommatePrefGender: json['roommatePrefGender'] as String?,
        verified: json['verified'] as bool? ?? false,
        stripeConnectId: json['stripeConnectId'] as String?,
        backgroundCheckStatus: json['backgroundCheckStatus'] as String?,
        backgroundCheckDate: json['backgroundCheckDate'] != null
            ? parseTimestamp(json['backgroundCheckDate'])
            : null,
        trustScore: json['trustScore'] as int? ?? 50,
        trustBadgeIds: List<String>.from(json['trustBadgeIds'] as List? ?? []),
        identityVerifiedAt: json['identityVerifiedAt'] != null
            ? parseTimestamp(json['identityVerifiedAt'])
            : null,
        identityDocumentSelfieVerified:
            json['identityDocumentSelfieVerified'] as bool? ?? false,
        cleanliness: getIntCompat('cleanliness', 5),
        sleepSchedule: getStringCompat('sleepSchedule', 'normal'),
        socialFrequency: getIntCompat('socialFrequency', 5),
        noiseTolerance: getIntCompat('noiseTolerance', 5),
        financialReliability: getIntCompat('financialReliability', 5),
        hasPets: getBoolCompat('hasPets'),
        petTolerance: getIntCompat('petTolerance', 5) != 5 ? getIntCompat('petTolerance', 5) : null,
        guestPolicy: getIntCompat('guestPolicy', 5) != 5 ? getIntCompat('guestPolicy', 5) : null,
        privacyNeed: getIntCompat('privacyNeed', 5) != 5 ? getIntCompat('privacyNeed', 5) : null,
        kitchenHabits: getIntCompat('kitchenHabits', 5) != 5 ? getIntCompat('kitchenHabits', 5) : null,
        createdAt: parseTimestamp(json['createdAt']),
        lastActiveAt: parseTimestamp(json['lastActiveAt']),
        isActive: json['isActive'] as bool? ?? true,
        isSuspended: json['isSuspended'] as bool? ?? false,
        suspensionReason: json['suspensionReason'] as String?,
      );
    } catch (e) {
      // Don't return a fallback - let parsing errors propagate
      // This ensures we properly detect when profile data is invalid or missing
      rethrow;
    }
  }

  /// Create copy with modifications
  UserProfile copyWith({
    String? name,
    int? age,
    String? avatar,
    String? bio,
    String? phone,
    bool? phoneVerified,
    String? email,
    bool? emailVerified,
    String? city,
    String? state,
    List<String>? neighborhoods,
    DateTime? moveInDate,
    double? budgetMin,
    double? budgetMax,
    String? roommatePrefGender,
    bool? verified,
    String? stripeConnectId,
    String? backgroundCheckStatus,
    DateTime? backgroundCheckDate,
    int? trustScore,
    List<String>? trustBadgeIds,
    DateTime? identityVerifiedAt,
    bool? identityDocumentSelfieVerified,
    int? cleanliness,
    String? sleepSchedule,
    int? socialFrequency,
    int? noiseTolerance,
    int? financialReliability,
    bool? hasPets,
    int? petTolerance,
    int? guestPolicy,
    int? privacyNeed,
    int? kitchenHabits,
    DateTime? lastActiveAt,
    bool? isActive,
    bool? isSuspended,
    String? suspensionReason,
  }) {
    return UserProfile(
      userId: userId,
      name: name ?? this.name,
      age: age ?? this.age,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      city: city ?? this.city,
      state: state ?? this.state,
      neighborhoods: neighborhoods ?? this.neighborhoods,
      moveInDate: moveInDate ?? this.moveInDate,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      roommatePrefGender: roommatePrefGender ?? this.roommatePrefGender,
      verified: verified ?? this.verified,
      stripeConnectId: stripeConnectId ?? this.stripeConnectId,
      backgroundCheckStatus:
          backgroundCheckStatus ?? this.backgroundCheckStatus,
      backgroundCheckDate: backgroundCheckDate ?? this.backgroundCheckDate,
      trustScore: trustScore ?? this.trustScore,
      trustBadgeIds: trustBadgeIds ?? this.trustBadgeIds,
      identityVerifiedAt: identityVerifiedAt ?? this.identityVerifiedAt,
      identityDocumentSelfieVerified:
          identityDocumentSelfieVerified ?? this.identityDocumentSelfieVerified,
      cleanliness: cleanliness ?? this.cleanliness,
      sleepSchedule: sleepSchedule ?? this.sleepSchedule,
      socialFrequency: socialFrequency ?? this.socialFrequency,
      noiseTolerance: noiseTolerance ?? this.noiseTolerance,
      financialReliability: financialReliability ?? this.financialReliability,
      hasPets: hasPets ?? this.hasPets,
      petTolerance: petTolerance ?? this.petTolerance,
      guestPolicy: guestPolicy ?? this.guestPolicy,
      privacyNeed: privacyNeed ?? this.privacyNeed,
      kitchenHabits: kitchenHabits ?? this.kitchenHabits,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isActive: isActive ?? this.isActive,
      isSuspended: isSuspended ?? this.isSuspended,
      suspensionReason: suspensionReason ?? this.suspensionReason,
    );
  }
}
