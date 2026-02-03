import '../../../core/services/api_service.dart';
import '../models/booking_model.dart';

class BookingServiceEnhanced {
  static final BookingServiceEnhanced _instance = BookingServiceEnhanced._internal();
  factory BookingServiceEnhanced() => _instance;
  BookingServiceEnhanced._internal();

  final ApiService _apiService = ApiService();

  // Get bookings
  Future<ApiResponse<List<BookingModel>>> getBookings({
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
        final bookings = (response.data['bookings'] as List)
            .map((json) => BookingModel.fromJson(json))
            .toList();
        return ApiResponse.success(bookings);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch bookings');
    } catch (e) {
      return ApiResponse.error('Failed to fetch bookings: $e');
    }
  }

  // Create payment intent
  Future<ApiResponse<Map<String, dynamic>>> createPaymentIntent(String bookingId) async {
    try {
      final response = await _apiService.post('/bookings/$bookingId/payment/intent');

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to create payment intent');
    } catch (e) {
      return ApiResponse.error('Failed to create payment intent: $e');
    }
  }

  // Confirm payment
  Future<ApiResponse<Map<String, dynamic>>> confirmPayment({
    required String bookingId,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiService.post(
        '/bookings/$bookingId/payment/confirm',
        data: {'paymentMethod': paymentMethod},
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to confirm payment');
    } catch (e) {
      return ApiResponse.error('Failed to confirm payment: $e');
    }
  }

  // Request reschedule
  Future<ApiResponse<Map<String, dynamic>>> requestReschedule({
    required String bookingId,
    required DateTime newDate,
    required String newStartTime,
    required String newEndTime,
    required String reason,
  }) async {
    try {
      final response = await _apiService.post(
        '/bookings/$bookingId/reschedule/request',
        data: {
          'newDate': newDate.toIso8601String(),
          'newStartTime': newStartTime,
          'newEndTime': newEndTime,
          'reason': reason,
        },
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to request reschedule');
    } catch (e) {
      return ApiResponse.error('Failed to request reschedule: $e');
    }
  }

  // Respond to reschedule request
  Future<ApiResponse<Map<String, dynamic>>> respondToReschedule({
    required String bookingId,
    required String requestId,
    required String response, // 'accept' or 'reject'
  }) async {
    try {
      final apiResponse = await _apiService.post(
        '/bookings/$bookingId/reschedule/$requestId/respond',
        data: {'response': response},
      );

      if (apiResponse.success && apiResponse.data != null) {
        return ApiResponse.success(apiResponse.data);
      }
      
      return ApiResponse.error(apiResponse.error ?? 'Failed to respond to reschedule');
    } catch (e) {
      return ApiResponse.error('Failed to respond to reschedule: $e');
    }
  }

  // Complete session
  Future<ApiResponse<Map<String, dynamic>>> completeSession({
    required String bookingId,
    String? sessionNotes,
  }) async {
    try {
      final response = await _apiService.post(
        '/bookings/$bookingId/complete',
        data: {'sessionNotes': sessionNotes},
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to complete session');
    } catch (e) {
      return ApiResponse.error('Failed to complete session: $e');
    }
  }

  // Add rating
  Future<ApiResponse<Map<String, dynamic>>> addRating({
    required String bookingId,
    required double score,
    String? review,
  }) async {
    try {
      final response = await _apiService.post(
        '/bookings/$bookingId/rating',
        data: {
          'score': score,
          'review': review,
        },
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to add rating');
    } catch (e) {
      return ApiResponse.error('Failed to add rating: $e');
    }
  }

  // Request refund
  Future<ApiResponse<Map<String, dynamic>>> requestRefund({
    required String bookingId,
    required String reason,
  }) async {
    try {
      final response = await _apiService.post(
        '/bookings/$bookingId/refund',
        data: {'reason': reason},
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to request refund');
    } catch (e) {
      return ApiResponse.error('Failed to request refund: $e');
    }
  }

  // Create dispute
  Future<ApiResponse<Map<String, dynamic>>> createDispute({
    required String bookingId,
    required String reason,
    required String description,
  }) async {
    try {
      final response = await _apiService.post(
        '/bookings/$bookingId/dispute',
        data: {
          'reason': reason,
          'description': description,
        },
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to create dispute');
    } catch (e) {
      return ApiResponse.error('Failed to create dispute: $e');
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

  // Cancel booking
  Future<ApiResponse<Map<String, dynamic>>> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    try {
      final response = await _apiService.put(
        '/bookings/$bookingId/cancel',
        data: {'reason': reason},
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to cancel booking');
    } catch (e) {
      return ApiResponse.error('Failed to cancel booking: $e');
    }
  }

  // Get booking details
  Future<ApiResponse<BookingModel>> getBookingDetails(String bookingId) async {
    try {
      final response = await _apiService.get('/bookings/$bookingId');

      if (response.success && response.data != null) {
        final booking = BookingModel.fromJson(response.data);
        return ApiResponse.success(booking);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch booking details');
    } catch (e) {
      return ApiResponse.error('Failed to fetch booking details: $e');
    }
  }
}
