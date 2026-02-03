import 'api_service.dart';

class TutorService {
  final ApiService _apiService = ApiService();

  // Search/Get all tutors with filters
  Future<ApiResponse<List<Map<String, dynamic>>>> searchTutors({
    String? search,
    String? subject,
    double? minPrice,
    double? maxPrice,
    String? teachingMode,
    String? location,
    double? minRating,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (subject != null && subject != 'All Subjects') {
        queryParams['subject'] = subject;
      }
      if (minPrice != null) {
        queryParams['minPrice'] = minPrice;
      }
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice;
      }
      if (teachingMode != null && teachingMode != 'All Modes') {
        queryParams['teachingMode'] = teachingMode;
      }
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (minRating != null && minRating > 0) {
        queryParams['rating'] = minRating;
      }

      final response = await _apiService.get('/tutors', queryParameters: queryParams);

      if (response.success && response.data != null) {
        final data = response.data['data'] ?? response.data;
        final tutorsList = data['tutors'] as List;
        final tutors = tutorsList.cast<Map<String, dynamic>>();
        return ApiResponse.success(tutors);
      }

      return ApiResponse.error(response.error ?? 'Failed to fetch tutors');
    } catch (e) {
      return ApiResponse.error('Failed to fetch tutors: $e');
    }
  }

  // Get tutor by ID
  Future<ApiResponse<Map<String, dynamic>>> getTutorById(String tutorId) async {
    try {
      final response = await _apiService.get('/tutors/$tutorId');

      if (response.success && response.data != null) {
        final tutor = response.data['data']?['tutor'] ?? response.data;
        return ApiResponse.success(tutor as Map<String, dynamic>);
      }

      return ApiResponse.error(response.error ?? 'Failed to fetch tutor');
    } catch (e) {
      return ApiResponse.error('Failed to fetch tutor: $e');
    }
  }

  // Get featured/recommended tutors
  Future<ApiResponse<List<Map<String, dynamic>>>> getFeaturedTutors({int limit = 10}) async {
    try {
      final response = await _apiService.get('/tutors', queryParameters: {
        'limit': limit,
        'rating': 4.5, // Only highly rated tutors
      });

      if (response.success && response.data != null) {
        final data = response.data['data'] ?? response.data;
        final tutorsList = data['tutors'] as List;
        final tutors = tutorsList.cast<Map<String, dynamic>>();
        return ApiResponse.success(tutors);
      }

      return ApiResponse.error(response.error ?? 'Failed to fetch featured tutors');
    } catch (e) {
      return ApiResponse.error('Failed to fetch featured tutors: $e');
    }
  }

  // Get tutor reviews
  Future<ApiResponse<Map<String, dynamic>>> getTutorReviews(String tutorId, {
    int page = 1,
    int limit = 20,
    int? rating,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (rating != null) queryParams['rating'] = rating;
      if (sortBy != null) queryParams['sortBy'] = sortBy;

      final response = await _apiService.get('/reviews/tutor/$tutorId', queryParameters: queryParams);

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch reviews');
    } catch (e) {
      return ApiResponse.error('Failed to fetch reviews: $e');
    }
  }

  // Toggle profile visibility
  Future<ApiResponse<Map<String, dynamic>>> toggleProfileVisibility(bool isActive) async {
    try {
      final response = await _apiService.put(
        '/tutors/profile/visibility',
        data: {'isActive': isActive},
      );

      if (response.success) {
        return ApiResponse.success(response.data);
      }

      return ApiResponse.error(response.error ?? 'Failed to toggle visibility');
    } catch (e) {
      return ApiResponse.error('Failed to toggle visibility: $e');
    }
  }

  // Toggle accepting bookings
  Future<ApiResponse<Map<String, dynamic>>> toggleAcceptingBookings(bool isAvailable) async {
    try {
      final response = await _apiService.put(
        '/tutors/profile/availability',
        data: {'isAvailable': isAvailable},
      );

      if (response.success) {
        return ApiResponse.success(response.data);
      }

      return ApiResponse.error(response.error ?? 'Failed to toggle availability');
    } catch (e) {
      return ApiResponse.error('Failed to toggle availability: $e');
    }
  }
}
