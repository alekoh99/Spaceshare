
/// Listing Model - Apartment/Room listings
class Listing {
  final String listingId;
  final String userId; // Landlord/current tenant
  final String title;
  final String description;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double latitude;
  final double longitude;
  final String propertyType; // 'apartment', 'house', 'room', 'shared_room'
  
  // Pricing
  final double rentAmount;
  final String currency; // 'USD', 'CAD', etc.
  final String paymentFrequency; // 'monthly', 'weekly'
  final double? securityDeposit;
  final double? utilities; // Monthly utilities estimate
  
  // Property Details
  final int bedrooms;
  final int bathrooms;
  final int squareFeet;
  final bool furnished;
  final List<String> amenities; // ['wifi', 'parking', 'laundry', 'ac', 'heating', etc.]
  
  // Availability
  final DateTime availableFrom;
  final DateTime? availableUntil;
  final int leaseLength; // in months, 0 for flexible
  
  // Occupancy
  final int totalOccupants;
  final int currentOccupants;
  final int spotsAvailable;
  final List<String> currentTenantIds;
  
  // Requirements
  final int minAge;
  final String? preferredGender; // 'M', 'F', 'Any'
  final bool petsAllowed;
  final bool smokingAllowed;
  final String? backgroundCheckRequired; // 'required', 'preferred', 'not_required'
  final double? minCreditScore;
  
  // Media
  final List<String> imageUrls;
  final List<String> videoUrls;
  
  // Status
  final String status; // 'active', 'pending', 'rented', 'archived'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastViewedAt;
  final int viewCount;
  final int favoriteCount;
  
  // Additional
  final Map<String, dynamic>? metadata;

  Listing({
    required this.listingId,
    required this.userId,
    required this.title,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
    required this.propertyType,
    required this.rentAmount,
    required this.currency,
    required this.paymentFrequency,
    this.securityDeposit,
    this.utilities,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFeet,
    required this.furnished,
    required this.amenities,
    required this.availableFrom,
    this.availableUntil,
    this.leaseLength = 12,
    required this.totalOccupants,
    required this.currentOccupants,
    required this.spotsAvailable,
    required this.currentTenantIds,
    this.minAge = 18,
    this.preferredGender,
    this.petsAllowed = false,
    this.smokingAllowed = false,
    this.backgroundCheckRequired,
    this.minCreditScore,
    required this.imageUrls,
    required this.videoUrls,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastViewedAt,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'listingId': listingId,
      'userId': userId,
      'title': title,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'propertyType': propertyType,
      'rentAmount': rentAmount,
      'currency': currency,
      'paymentFrequency': paymentFrequency,
      'securityDeposit': securityDeposit,
      'utilities': utilities,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFeet': squareFeet,
      'furnished': furnished,
      'amenities': amenities,
      'availableFrom': availableFrom.toIso8601String(),
      'availableUntil': availableUntil != null ? availableUntil!.toIso8601String() : null,
      'leaseLength': leaseLength,
      'totalOccupants': totalOccupants,
      'currentOccupants': currentOccupants,
      'spotsAvailable': spotsAvailable,
      'currentTenantIds': currentTenantIds,
      'minAge': minAge,
      'preferredGender': preferredGender,
      'petsAllowed': petsAllowed,
      'smokingAllowed': smokingAllowed,
      'backgroundCheckRequired': backgroundCheckRequired,
      'minCreditScore': minCreditScore,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastViewedAt': lastViewedAt != null ? lastViewedAt!.toIso8601String() : null,
      'viewCount': viewCount,
      'favoriteCount': favoriteCount,
      'metadata': metadata,
    };
  }

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      listingId: json['listingId'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      propertyType: json['propertyType'] as String,
      rentAmount: (json['rentAmount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      paymentFrequency: json['paymentFrequency'] as String? ?? 'monthly',
      securityDeposit: json['securityDeposit'] != null ? (json['securityDeposit'] as num).toDouble() : null,
      utilities: json['utilities'] != null ? (json['utilities'] as num).toDouble() : null,
      bedrooms: json['bedrooms'] as int,
      bathrooms: json['bathrooms'] as int,
      squareFeet: json['squareFeet'] as int,
      furnished: json['furnished'] as bool? ?? false,
      amenities: List<String>.from(json['amenities'] as List? ?? []),
      availableFrom: DateTime.parse(json['availableFrom'] as String),
      availableUntil: json['availableUntil'] != null ? DateTime.parse(json['availableUntil'] as String) : null,
      leaseLength: json['leaseLength'] as int? ?? 12,
      totalOccupants: json['totalOccupants'] as int,
      currentOccupants: json['currentOccupants'] as int,
      spotsAvailable: json['spotsAvailable'] as int,
      currentTenantIds: List<String>.from(json['currentTenantIds'] as List? ?? []),
      minAge: json['minAge'] as int? ?? 18,
      preferredGender: json['preferredGender'] as String?,
      petsAllowed: json['petsAllowed'] as bool? ?? false,
      smokingAllowed: json['smokingAllowed'] as bool? ?? false,
      backgroundCheckRequired: json['backgroundCheckRequired'] as String?,
      minCreditScore: json['minCreditScore'] != null ? (json['minCreditScore'] as num).toDouble() : null,
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      videoUrls: List<String>.from(json['videoUrls'] as List? ?? []),
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastViewedAt: json['lastViewedAt'] != null ? DateTime.parse(json['lastViewedAt'] as String) : null,
      viewCount: json['viewCount'] as int? ?? 0,
      favoriteCount: json['favoriteCount'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Listing copyWith({
    String? title,
    String? description,
    double? rentAmount,
    int? currentOccupants,
    int? spotsAvailable,
    String? status,
  }) {
    return Listing(
      listingId: listingId,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
      latitude: latitude,
      longitude: longitude,
      propertyType: propertyType,
      rentAmount: rentAmount ?? this.rentAmount,
      currency: currency,
      paymentFrequency: paymentFrequency,
      securityDeposit: securityDeposit,
      utilities: utilities,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      squareFeet: squareFeet,
      furnished: furnished,
      amenities: amenities,
      availableFrom: availableFrom,
      availableUntil: availableUntil,
      leaseLength: leaseLength,
      totalOccupants: totalOccupants,
      currentOccupants: currentOccupants ?? this.currentOccupants,
      spotsAvailable: spotsAvailable ?? this.spotsAvailable,
      currentTenantIds: currentTenantIds,
      minAge: minAge,
      preferredGender: preferredGender,
      petsAllowed: petsAllowed,
      smokingAllowed: smokingAllowed,
      backgroundCheckRequired: backgroundCheckRequired,
      minCreditScore: minCreditScore,
      imageUrls: imageUrls,
      videoUrls: videoUrls,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastViewedAt: lastViewedAt,
      viewCount: viewCount,
      favoriteCount: favoriteCount,
      metadata: metadata,
    );
  }
}
