import '../../../core/services/api_service.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final ApiService _apiService = ApiService();

  // Get bookings for current user
  Future<ApiResponse<List<Map<String, dynamic>>>> getBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiService.get('/bookings', queryParameters: queryParams);
      
      if (response.success && response.data != null) {
        final bookings = List<Map<String, dynamic>>.from(response.data['bookings'] ?? []);
        return ApiResponse.success(bookings);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch bookings');
    } catch (e) {
      return ApiResponse.error('Failed to fetch bookings: $e');
    }
  }

  // Create new booking request
  Future<ApiResponse<Map<String, dynamic>>> createBooking({
    required String tutorId,
    required String subjectId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String mode, // 'online' or 'in-person'
    String? location,
    String? message,
  }) async {
    try {
      final response = await _apiService.post('/bookings', data: {
        'tutorId': tutorId,
        'subjectId': subjectId,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'mode': mode,
        'location': location,
        'message': message,
      });

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to create booking');
    } catch (e) {
      return ApiResponse.error('Failed to create booking: $e');
    }
  }

  // Respond to booking request (for tutors)
  Future<ApiResponse<Map<String, dynamic>>> respondToBooking({
    required String bookingId,
    required String status, // 'accepted' or 'declined'
    String? message,
  }) async {
    try {
      final response = await _apiService.put('/bookings/$bookingId/respond', data: {
        'status': status,
        'message': message,
      });

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to respond to booking');
    } catch (e) {
      return ApiResponse.error('Failed to respond to booking: $e');
    }
  }

  // Cancel booking
  Future<ApiResponse<Map<String, dynamic>>> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    try {
      final response = await _apiService.put('/bookings/$bookingId/cancel', data: {
        'reason': reason,
      });

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to cancel booking');
    } catch (e) {
      return ApiResponse.error('Failed to cancel booking: $e');
    }
  }

  // Reschedule booking
  Future<ApiResponse<Map<String, dynamic>>> rescheduleBooking({
    required String bookingId,
    required DateTime newDate,
    required String newStartTime,
    required String newEndTime,
    String? reason,
  }) async {
    try {
      final response = await _apiService.put('/bookings/$bookingId/reschedule', data: {
        'newDate': newDate.toIso8601String(),
        'newStartTime': newStartTime,
        'newEndTime': newEndTime,
        'reason': reason,
      });

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to reschedule booking');
    } catch (e) {
      return ApiResponse.error('Failed to reschedule booking: $e');
    }
  }

  // Mark session as completed
  Future<ApiResponse<Map<String, dynamic>>> completeSession({
    required String bookingId,
    String? notes,
  }) async {
    try {
      final response = await _apiService.put('/bookings/$bookingId/complete', data: {
        'notes': notes,
      });

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to complete session');
    } catch (e) {
      return ApiResponse.error('Failed to complete session: $e');
    }
  }

  // Get booking details
  Future<ApiResponse<Map<String, dynamic>>> getBookingDetails(String bookingId) async {
    try {
      final response = await _apiService.get('/bookings/$bookingId');

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch booking details');
    } catch (e) {
      return ApiResponse.error('Failed to fetch booking details: $e');
    }
  }

  // Get earnings (for tutors)
  Future<ApiResponse<Map<String, dynamic>>> getEarnings({
    String? period, // 'week', 'month', 'year'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _apiService.get('/bookings/earnings', queryParameters: queryParams);

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch earnings');
    } catch (e) {
      return ApiResponse.error('Failed to fetch earnings: $e');
    }
  }

  // Get dashboard stats
  Future<ApiResponse<Map<String, dynamic>>> getDashboardStats() async {
    try {
      final response = await _apiService.get('/bookings/dashboard-stats');

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch dashboard stats');
    } catch (e) {
      return ApiResponse.error('Failed to fetch dashboard stats: $e');
    }
  }

  // Rate session
  Future<ApiResponse<Map<String, dynamic>>> rateSession({
    required String bookingId,
    required double rating,
    String? review,
    Map<String, int>? categories,
  }) async {
    try {
      final response = await _apiService.post('/bookings/$bookingId/rate', data: {
        'rating': rating,
        'review': review,
        'categories': categories,
      });

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to submit rating');
    } catch (e) {
      return ApiResponse.error('Failed to submit rating: $e');
    }
  }
}