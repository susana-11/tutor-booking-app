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

      print('🔍 TUTOR SERVICE: Searching tutors with params: $queryParams');
      
      final response = await _apiService.get('/tutors', queryParameters: queryParams);

      print('📡 TUTOR SERVICE: Response success: ${response.success}');
      print('📡 TUTOR SERVICE: Response data type: ${response.data.runtimeType}');
      print('📡 TUTOR SERVICE: Response data keys: ${response.data is Map ? (response.data as Map).keys.toList() : "not a map"}');

      if (response.success && response.data != null) {
        List<Map<String, dynamic>> tutors = [];
        
        // The API returns: { success: true, data: { tutors: [...], pagination: {...} } }
        if (response.data is Map) {
          final responseMap = response.data as Map<String, dynamic>;
          
          // Check if there's a 'data' wrapper
          if (responseMap.containsKey('data')) {
            final dataObj = responseMap['data'];
            print('📋 TUTOR SERVICE: Found data key, type: ${dataObj.runtimeType}');
            
            if (dataObj is Map && dataObj.containsKey('tutors')) {
              // data.tutors format
              final tutorsList = dataObj['tutors'] as List;
              tutors = tutorsList.cast<Map<String, dynamic>>();
              print('✅ TUTOR SERVICE: Found tutors in data.tutors, count: ${tutors.length}');
            } else if (dataObj is List) {
              // data is directly a list
              tutors = dataObj.cast<Map<String, dynamic>>();
              print('✅ TUTOR SERVICE: data is a list, count: ${tutors.length}');
            }
          } else if (responseMap.containsKey('tutors')) {
            // Direct tutors key
            final tutorsList = responseMap['tutors'] as List;
            tutors = tutorsList.cast<Map<String, dynamic>>();
            print('✅ TUTOR SERVICE: Found tutors directly, count: ${tutors.length}');
          }
        } else if (response.data is List) {
          // Direct array response
          tutors = (response.data as List).cast<Map<String, dynamic>>();
          print('✅ TUTOR SERVICE: Response is direct array, count: ${tutors.length}');
        }
        
        print('✅ TUTOR SERVICE: Final tutor count: ${tutors.length}');
        if (tutors.isNotEmpty) {
          print('📋 TUTOR SERVICE: First tutor keys: ${tutors[0].keys.toList()}');
          print('📋 TUTOR SERVICE: First tutor name: ${tutors[0]['name']}');
        }
        return ApiResponse.success(tutors);
      }

      print('❌ TUTOR SERVICE: Response failed: ${response.error}');
      return ApiResponse.error(response.error ?? 'Failed to fetch tutors');
    } catch (e, stackTrace) {
      print('❌ TUTOR SERVICE: Exception: $e');
      print('❌ TUTOR SERVICE: Stack trace: $stackTrace');
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
        // The API returns tutors directly as an array, not wrapped in an object
        List<Map<String, dynamic>> tutors;
        
        if (response.data is List) {
          // Direct array response
          tutors = (response.data as List).cast<Map<String, dynamic>>();
        } else if (response.data is Map) {
          // Check for nested data structure
          final data = response.data['data'] ?? response.data;
          if (data is List) {
            tutors = data.cast<Map<String, dynamic>>();
          } else if (data['tutors'] != null) {
            tutors = (data['tutors'] as List).cast<Map<String, dynamic>>();
          } else {
            tutors = [];
          }
        } else {
          tutors = [];
        }
        
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
