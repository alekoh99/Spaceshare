import 'package:get/get.dart';
import '../models/review_model.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart' as exceptions;
import 'firebase_realtime_database_service.dart';

/// Review Service - Manages user reviews and ratings
class ReviewService extends GetxService {
  late final FirebaseRealtimeDatabaseService _databaseService;

  @override
  void onInit() {
    super.onInit();
    _databaseService = Get.find<FirebaseRealtimeDatabaseService>();
  }

  /// Create a new review
  Future<String> createReview(RoommateReview review) async {
    try {
      await _databaseService.createPath('reviews/${review.reviewId}', review.toJson());
      AppLogger.success('ReviewService', 'Review created: ${review.reviewId}');
      return review.reviewId;
    } catch (e) {
      AppLogger.error('ReviewService', 'Failed to create review', e);
      throw exceptions.ServiceException('Failed to create review: $e');
    }
  }

  /// Get reviews for a user
  Future<List<RoommateReview>> getUserReviews(
    String userId, {
    bool publishedOnly = true,
  }) async {
    try {
      final result = await _databaseService.readPath('reviewsByUser/$userId');
      if (result.isSuccess()) {
        final reviewsData = result.getOrNull();
        final reviews = <RoommateReview>[];
        if (reviewsData is Map) {
          final reviewsMap = reviewsData as Map<dynamic, dynamic>?;
          if (reviewsMap != null) {
            reviewsMap.forEach((key, value) {
              try {
                if (value is Map) {
                  final review = RoommateReview.fromJson(Map<String, dynamic>.from(value as Map<dynamic, dynamic>));
                  if (!publishedOnly || review.status == 'published') {
                    reviews.add(review);
                  }
                }
              } catch (e) {
                AppLogger.debug('ReviewService', 'Failed to parse review: $e');
              }
            });
          }
        }
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reviews;
      }
      return [];
    } catch (e) {
      AppLogger.error('ReviewService', 'Failed to get user reviews', e);
      throw exceptions.ServiceException('Failed to get user reviews: $e');
    }
  }

  /// Get average rating for a user
  Future<double> getUserAverageRating(String userId) async {
    try {
      final reviews = await getUserReviews(userId, publishedOnly: true);
      if (reviews.isEmpty) return 0.0;

      double totalRating = 0;
      for (var review in reviews) {
        totalRating += review.rating;
      }

      return totalRating / reviews.length;
    } catch (e) {
      AppLogger.debug('ReviewService', 'Failed to calculate average rating');
      return 0.0;
    }
  }

  /// Get reviews written by a user
  Future<List<RoommateReview>> getReviewsByReviewer(String reviewerId) async {
    try {
      final result = await _databaseService.readPath('reviewsByReviewer/$reviewerId');
      if (result.isSuccess()) {
        final reviewsData = result.getOrNull();
        final reviews = <RoommateReview>[];
        if (reviewsData is Map) {
          final reviewsMap = reviewsData as Map<dynamic, dynamic>?;
          if (reviewsMap != null) {
            reviewsMap.forEach((key, value) {
              try {
                if (value is Map) {
                  reviews.add(RoommateReview.fromJson(Map<String, dynamic>.from(value as Map<dynamic, dynamic>)));
                }
              } catch (e) {
                AppLogger.debug('ReviewService', 'Failed to parse review: $e');
              }
            });
          }
        }
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reviews;
      }
      return [];
    } catch (e) {
      AppLogger.error('ReviewService', 'Failed to get reviewer reviews', e);
      throw exceptions.ServiceException('Failed to get reviewer reviews: $e');
    }
  }

  /// Get review for a specific match
  Future<RoommateReview?> getMatchReview(
    String matchId,
    String reviewerId,
  ) async {
    try {
      final result = await _databaseService.readPath('matchReviews/$matchId/$reviewerId');
      if (result.isSuccess()) {
        final data = result.getOrNull();
        if (data is Map) {
          return RoommateReview.fromJson(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
        }
      }
      return null;
    } catch (e) {
      AppLogger.debug('ReviewService', 'Failed to get match review');
      return null;
    }
  }

  /// Update review
  Future<void> updateReview(String reviewId, RoommateReview review) async {
    try {
      final updates = review.toJson();
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _databaseService.updatePath('reviews/$reviewId', updates);
      AppLogger.success('ReviewService', 'Review updated: $reviewId');
    } catch (e) {
      AppLogger.error('ReviewService', 'Failed to update review', e);
      throw exceptions.ServiceException('Failed to update review: $e');
    }
  }

  /// Mark review as helpful
  Future<void> markHelpful(String reviewId) async {
    try {
      final result = await _databaseService.readPath('reviews/$reviewId');
      if (result.isSuccess()) {
        final data = result.getOrNull();
        if (data is Map) {
          final review = Map<String, dynamic>.from(data as Map<dynamic, dynamic>);
          final currentCount = (review['helpfulCount'] as num?)?.toInt() ?? 0;
          await _databaseService.updatePath('reviews/$reviewId', {
            'helpfulCount': currentCount + 1,
          });
        }
      }
    } catch (e) {
      AppLogger.debug('ReviewService', 'Non-critical: Failed to mark helpful');
    }
  }

  /// Mark review as unhelpful
  Future<void> markUnhelpful(String reviewId) async {
    try {
      final result = await _databaseService.readPath('reviews/$reviewId');
      if (result.isSuccess()) {
        final data = result.getOrNull();
        if (data is Map) {
          final review = Map<String, dynamic>.from(data as Map<dynamic, dynamic>);
          final currentCount = (review['unhelpfulCount'] as num?)?.toInt() ?? 0;
          await _databaseService.updatePath('reviews/$reviewId', {
            'unhelpfulCount': currentCount + 1,
          });
        }
      }
    } catch (e) {
      AppLogger.debug('ReviewService', 'Non-critical: Failed to mark unhelpful');
    }
  }

  /// Flag review as inappropriate
  Future<void> flagReview(
    String reviewId,
    String userId,
    String reason,
  ) async {
    try {
      final result = await _databaseService.readPath('reviews/$reviewId');
      if (result.isSuccess()) {
        final data = result.getOrNull();
        if (data is Map) {
          final review = Map<String, dynamic>.from(data as Map<dynamic, dynamic>);
          final flaggedBy = List<String>.from(review['flaggedBy'] as List? ?? []);
          if (!flaggedBy.contains(userId)) {
            flaggedBy.add(userId);
          }
          
          final updates = {
            'flaggedBy': flaggedBy,
            'flagReason': reason,
          };
          
          if (flaggedBy.length >= 3) {
            updates['status'] = 'flagged_for_review';
          }
          
          await _databaseService.updatePath('reviews/$reviewId', updates);
        }
      }
      AppLogger.info('ReviewService', 'Review flagged: $reviewId');
    } catch (e) {
      AppLogger.error('ReviewService', 'Failed to flag review', e);
      throw exceptions.ServiceException('Failed to flag review: $e');
    }
  }

  /// Delete review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _databaseService.deletePath('reviews/$reviewId');
      AppLogger.success('ReviewService', 'Review deleted: $reviewId');
    } catch (e) {
      AppLogger.error('ReviewService', 'Failed to delete review', e);
      throw exceptions.ServiceException('Failed to delete review: $e');
    }
  }

  /// Get review statistics for a user
  Future<Map<String, dynamic>> getUserReviewStats(String userId) async {
    try {
      final reviews = await getUserReviews(userId, publishedOnly: true);

      if (reviews.isEmpty) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'averageCleanlinessRating': 0.0,
          'averageNoiseRating': 0.0,
          'averageRespectRating': 0.0,
          'averageCommunicationRating': 0.0,
          'averageReliabilityRating': 0.0,
        };
      }

      double totalRating = 0;
      double totalCleanliness = 0;
      double totalNoise = 0;
      double totalRespect = 0;
      double totalCommunication = 0;
      double totalReliability = 0;

      for (var review in reviews) {
        totalRating += review.rating;
        totalCleanliness += review.cleanlinessRating;
        totalNoise += review.noiseRating;
        totalRespect += review.respectRating;
        totalCommunication += review.communicationRating;
        totalReliability += review.reliabilityRating;
      }

      final count = reviews.length.toDouble();

      return {
        'totalReviews': reviews.length,
        'averageRating': totalRating / count,
        'averageCleanlinessRating': totalCleanliness / count,
        'averageNoiseRating': totalNoise / count,
        'averageRespectRating': totalRespect / count,
        'averageCommunicationRating': totalCommunication / count,
        'averageReliabilityRating': totalReliability / count,
      };
    } catch (e) {
      AppLogger.error('ReviewService', 'Failed to get review statistics', e);
      throw exceptions.ServiceException('Failed to get review statistics: $e');
    }
  }
}
