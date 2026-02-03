import 'api_service.dart';
import '../models/review_models.dart';

class ReviewService {
  final ApiService _apiService;

  ReviewService(this._apiService);

  // Create a review for a completed booking
  Future<Review> createReview({
    required String bookingId,
    required int rating,
    String? reviewText,
    Map<String, int>? categories,
  }) async {
    try {
      final response = await _apiService.post('/reviews', data: {
        'bookingId': bookingId,
        'rating': rating,
        if (reviewText != null && reviewText.isNotEmpty) 'review': reviewText,
        if (categories != null) 'categories': categories,
      });

      if (response.success && response.data != null) {
        return Review.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.error ?? response.message ?? 'Failed to create review');
      }
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  // Get reviews for a tutor
  Future<ReviewsResponse> getTutorReviews({
    required String tutorId,
    int page = 1,
    int limit = 20,
    int? rating,
    String sortBy = 'recent', // recent, helpful, rating_high, rating_low
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (rating != null) 'rating': rating.toString(),
        'sortBy': sortBy,
      };

      final response = await _apiService.get(
        '/reviews/tutor/$tutorId',
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        return ReviewsResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.error ?? response.message ?? 'Failed to get reviews');
      }
    } catch (e) {
      throw Exception('Failed to get tutor reviews: $e');
    }
  }

  // Get reviews written by a student
  Future<List<Review>> getStudentReviews({
    required String studentId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _apiService.get(
        '/reviews/student/$studentId',
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final reviews = (data['reviews'] as List)
            .map((r) => Review.fromJson(r))
            .toList();
        return reviews;
      } else {
        throw Exception(response.error ?? response.message ?? 'Failed to get reviews');
      }
    } catch (e) {
      throw Exception('Failed to get student reviews: $e');
    }
  }

  // Get a single review
  Future<Review> getReview(String reviewId) async {
    try {
      final response = await _apiService.get('/reviews/$reviewId');

      if (response.success && response.data != null) {
        return Review.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.error ?? response.message ?? 'Failed to get review');
      }
    } catch (e) {
      throw Exception('Failed to get review: $e');
    }
  }

  // Update a review (within 24 hours)
  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    required String reviewText,
  }) async {
    try {
      final response = await _apiService.put('/reviews/$reviewId', data: {
        'rating': rating,
        'review': reviewText,
      });

      if (response.success && response.data != null) {
        return Review.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.error ?? response.message ?? 'Failed to update review');
      }
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      final response = await _apiService.delete('/reviews/$reviewId');

      if (!response.success) {
        throw Exception(response.error ?? response.message ?? 'Failed to delete review');
      }
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Mark review as helpful or not helpful
  Future<void> markHelpful({
    required String reviewId,
    required bool helpful,
  }) async {
    try {
      final response = await _apiService.put('/reviews/$reviewId/helpful', data: {
        'helpful': helpful,
      });

      if (!response.success) {
        throw Exception(response.error ?? response.message ?? 'Failed to mark review');
      }
    } catch (e) {
      throw Exception('Failed to mark review as helpful: $e');
    }
  }

  // Tutor responds to a review
  Future<Review> addTutorResponse({
    required String reviewId,
    required String response,
  }) async {
    try {
      final apiResponse = await _apiService.post('/reviews/$reviewId/response', data: {
        'response': response,
      });

      if (apiResponse.success && apiResponse.data != null) {
        return Review.fromJson(apiResponse.data as Map<String, dynamic>);
      } else {
        throw Exception(apiResponse.error ?? apiResponse.message ?? 'Failed to add response');
      }
    } catch (e) {
      throw Exception('Failed to add tutor response: $e');
    }
  }

  // Flag a review for moderation
  Future<void> flagReview({
    required String reviewId,
    required String reason,
  }) async {
    try {
      final response = await _apiService.post('/reviews/$reviewId/flag', data: {
        'reason': reason,
      });

      if (!response.success) {
        throw Exception(response.error ?? response.message ?? 'Failed to flag review');
      }
    } catch (e) {
      throw Exception('Failed to flag review: $e');
    }
  }

  // Check if a booking can be reviewed
  Future<bool> canReviewBooking(String bookingId) async {
    try {
      // Check if review already exists for this booking
      final response = await _apiService.get('/bookings/$bookingId');
      
      if (response.success && response.data != null) {
        final booking = response.data as Map<String, dynamic>;
        // Can review if completed and not already reviewed
        return booking['status'] == 'completed' && 
               (booking['rating'] == null || booking['rating']['student'] == null);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
