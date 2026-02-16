import 'package:get/get.dart';
import '../models/listing_model.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart' as exceptions;
import '../utils/result.dart';
import 'unified_database_service.dart';

/// Listing Service - Manages apartment/room listings
class ListingService extends GetxService {
  late final UnifiedDatabaseService _databaseService;

  @override
  void onInit() {
    super.onInit();
    _databaseService = Get.find<UnifiedDatabaseService>();
  }

  /// Create a new listing
  Future<String> createListing(Listing listing) async {
    try {
      await _databaseService.createPath(
        'listings/${listing.listingId}',
        listing.toJson(),
      );
      AppLogger.success('ListingService', 'Listing created: ${listing.listingId}');
      return listing.listingId;
    } catch (e) {
      AppLogger.error('ListingService', 'Failed to create listing', e);
      throw exceptions.ServiceException('Failed to create listing: $e');
    }
  }

  /// Get listing by ID
  Future<Listing> getListing(String listingId) async {
    try {
      final result = await _databaseService.readPath('listings/$listingId');
      if (!result.isSuccess() || result.data == null) {
        throw exceptions.ServiceException('Listing not found');
      }
      final data = Map<String, dynamic>.from(result.data!);
      return Listing.fromJson(data);
    } catch (e) {
      AppLogger.error('ListingService', 'Failed to get listing', e);
      throw exceptions.ServiceException('Failed to get listing: $e');
    }
  }

  /// Get listings by user (landlord)
  Future<List<Listing>> getUserListings(String userId) async {
    try {
      final allListings = await _databaseService.readPath('listings') as Map<String, dynamic>?;
      if (allListings == null || allListings.isEmpty) {
        return [];
      }
      
      final listings = <Listing>[];
      allListings.forEach((key, value) {
        final data = Map<String, dynamic>.from(value as Map);
        if (data['userId'] == userId) {
          listings.add(Listing.fromJson(data));
        }
      });
      
      // Sort by createdAt descending
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return listings;
    } catch (e) {
      AppLogger.error('ListingService', 'Failed to get user listings', e);
      throw exceptions.ServiceException('Failed to get user listings: $e');
    }
  }

  /// Search listings by city and budget
  Future<List<Listing>> searchListings({
    required String city,
    double? maxRent,
    String? propertyType,
    int limit = 50,
  }) async {
    try {
      final allListings = await _databaseService.readPath('listings') as Map<String, dynamic>?;
      if (allListings == null || allListings.isEmpty) {
        return [];
      }

      final listings = <Listing>[];
      allListings.forEach((key, value) {
        if (listings.length >= limit) return;
        
        final data = Map<String, dynamic>.from(value as Map);
        final listing = Listing.fromJson(data);
        
        if (listing.city != city || listing.status != 'active') {
          return;
        }
        
        if (maxRent != null && listing.rentAmount > maxRent) {
          return;
        }
        
        if (propertyType != null && listing.propertyType != propertyType) {
          return;
        }
        
        listings.add(listing);
      });

      listings.sort((a, b) => a.rentAmount.compareTo(b.rentAmount));
      return listings;
    } catch (e) {
      AppLogger.error('ListingService', 'Failed to search listings', e);
      throw exceptions.ServiceException('Failed to search listings: $e');
    }
  }

  /// Get nearby listings (within radius)
  Future<List<Listing>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 50,
  }) async {
    try {
      final radiusDegrees = radiusKm / 111.0; // 1 degree ≈ 111 km
      final allListings = await _databaseService.readPath('listings') as Map<String, dynamic>?;
      
      if (allListings == null || allListings.isEmpty) {
        return [];
      }

      final listings = <Listing>[];
      allListings.forEach((key, value) {
        if (listings.length >= limit) return;
        
        final data = Map<String, dynamic>.from(value as Map);
        final listing = Listing.fromJson(data);
        
        if (listing.status != 'active') {
          return;
        }
        
        final latDiff = (listing.latitude - latitude).abs();
        final lonDiff = (listing.longitude - longitude).abs();
        
        if (latDiff <= radiusDegrees && lonDiff <= radiusDegrees) {
          listings.add(listing);
        }
      });

      return listings;
    } catch (e) {
      AppLogger.error('ListingService', 'Failed to get nearby listings', e);
      throw exceptions.ServiceException('Failed to get nearby listings: $e');
    }
  }

  /// Update listing
  Future<void> updateListing(String listingId, Listing listing) async {
    try {
      final updateData = listing.toJson();
      updateData['updatedAt'] = DateTime.now().toIso8601String();
      
      await _databaseService.updatePath(
        'listings/$listingId',
        updateData,
      );
      AppLogger.success('ListingService', 'Listing updated: $listingId');
    } catch (e) {
      AppLogger.error('ListingService', 'Failed to update listing', e);
      throw exceptions.ServiceException('Failed to update listing: $e');
    }
  }

  /// Increment view count
  Future<void> incrementViewCount(String listingId) async {
    try {
      final result = await _databaseService.readPath('listings/$listingId');
      if (result.isSuccess() && result.data != null) {
        final data = Map<String, dynamic>.from(result.data!);
        final viewCount = (data['viewCount'] as int? ?? 0) + 1;
        
        await _databaseService.updatePath(
          'listings/$listingId',
          {
            'viewCount': viewCount,
            'lastViewedAt': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      AppLogger.debug('ListingService', 'Non-critical: Failed to increment view count');
    }
  }

  /// Toggle favorite listing
  Future<void> toggleFavorite(String listingId, bool isFavorite) async {
    try {
      final result = await _databaseService.readPath('listings/$listingId');
      if (result.isSuccess() && result.data != null) {
        final data = Map<String, dynamic>.from(result.data!);
        final favoriteCount = (data['favoriteCount'] as int? ?? 0);
        
        await _databaseService.updatePath(
          'listings/$listingId',
          {
            'favoriteCount': favoriteCount + (isFavorite ? 1 : -1),
          },
        );
      }
    } catch (e) {
      AppLogger.debug('ListingService', 'Non-critical: Failed to toggle favorite');
    }
  }

  /// Delete listing
  Future<void> deleteListing(String listingId) async {
    try {
      await _databaseService.deletePath('listings/$listingId');
      AppLogger.success('ListingService', 'Listing deleted: $listingId');
    } catch (e) {
      AppLogger.error('ListingService', 'Failed to delete listing', e);
      throw exceptions.ServiceException('Failed to delete listing: $e');
    }
  }

  /// Get active listings count
  Future<int> getActiveListingsCount(String userId) async {
    try {
      final allListings = await _databaseService.readPath('listings') as Map<String, dynamic>?;
      if (allListings == null || allListings.isEmpty) {
        return 0;
      }
      
      int count = 0;
      allListings.forEach((key, value) {
        final data = Map<String, dynamic>.from(value as Map);
        if (data['userId'] == userId && data['status'] == 'active') {
          count++;
        }
      });
      
      return count;
    } catch (e) {
      AppLogger.debug('ListingService', 'Failed to count listings');
      return 0;
    }
  }
}
