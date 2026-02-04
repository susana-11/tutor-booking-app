import '../../../core/services/api_service.dart';
import '../models/availability_model.dart';

class AvailabilityService {
  static final AvailabilityService _instance = AvailabilityService._internal();
  factory AvailabilityService() => _instance;
  AvailabilityService._internal();

  final ApiService _apiService = ApiService();

  // Get tutor's weekly schedule
  Future<ApiResponse<WeeklySchedule>> getWeeklySchedule({
    required DateTime weekStart,
  }) async {
    try {
      final response = await _apiService.get('/availability/weekly', queryParameters: {
        'weekStart': weekStart.toIso8601String(),
      });

      if (response.success && response.data != null) {
        final schedule = WeeklySchedule.fromJson(response.data);
        return ApiResponse.success(schedule);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch weekly schedule');
    } catch (e) {
      return ApiResponse.error('Failed to fetch weekly schedule: $e');
    }
  }

  // Get availability slots for a specific date range
  Future<ApiResponse<List<AvailabilitySlot>>> getAvailabilitySlots({
    required DateTime startDate,
    required DateTime endDate,
    String? tutorId, // Optional tutorId for students
  }) async {
    try {
      final queryParameters = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
      
      // Add tutorId if provided (for students)
      if (tutorId != null) {
        queryParameters['tutorId'] = tutorId;
      }

      final response = await _apiService.get('/availability/slots', queryParameters: queryParameters);

      if (response.success && response.data != null) {
        final slots = (response.data as List)
            .map((slot) => AvailabilitySlot.fromJson(slot))
            .toList();
        return ApiResponse.success(slots);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch availability slots');
    } catch (e) {
      return ApiResponse.error('Failed to fetch availability slots: $e');
    }
  }

  // Create a new availability slot
  Future<ApiResponse<AvailabilitySlot>> createAvailabilitySlot({
    required DateTime date,
    required String startTime,
    required String endTime,
    bool isRecurring = false,
    String? recurringPattern,
  }) async {
    try {
      final response = await _apiService.post('/availability/slots', data: {
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'isRecurring': isRecurring,
        'recurringPattern': recurringPattern,
      });

      if (response.success && response.data != null) {
        final slot = AvailabilitySlot.fromJson(response.data);
        return ApiResponse.success(slot);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to create availability slot');
    } catch (e) {
      return ApiResponse.error('Failed to create availability slot: $e');
    }
  }

  // Update an existing availability slot
  Future<ApiResponse<AvailabilitySlot>> updateAvailabilitySlot({
    required String slotId,
    DateTime? date,
    String? startTime,
    String? endTime,
    bool? isAvailable,
    bool? isRecurring,
    String? recurringPattern,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (date != null) data['date'] = date.toIso8601String();
      if (startTime != null) data['startTime'] = startTime;
      if (endTime != null) data['endTime'] = endTime;
      if (isAvailable != null) data['isAvailable'] = isAvailable;
      if (isRecurring != null) data['isRecurring'] = isRecurring;
      if (recurringPattern != null) data['recurringPattern'] = recurringPattern;

      final response = await _apiService.put('/availability/slots/$slotId', data: data);

      if (response.success && response.data != null) {
        final slot = AvailabilitySlot.fromJson(response.data);
        return ApiResponse.success(slot);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to update availability slot');
    } catch (e) {
      return ApiResponse.error('Failed to update availability slot: $e');
    }
  }

  // Delete an availability slot
  Future<ApiResponse<bool>> deleteAvailabilitySlot(String slotId, {bool cancelBooking = false}) async {
    try {
      final response = await _apiService.delete(
        '/availability/slots/$slotId',
        data: {'cancelBooking': cancelBooking},
      );

      if (response.success) {
        return ApiResponse.success(true);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to delete availability slot');
    } catch (e) {
      return ApiResponse.error('Failed to delete availability slot: $e');
    }
  }

  // Toggle slot availability
  Future<ApiResponse<Map<String, dynamic>>> toggleSlotAvailability({
    required String slotId,
    required bool makeAvailable,
    bool cancelBooking = false,
  }) async {
    try {
      final response = await _apiService.put(
        '/availability/slots/$slotId/toggle-availability',
        data: {
          'makeAvailable': makeAvailable,
          'cancelBooking': cancelBooking,
        },
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }

      return ApiResponse.error(response.error ?? 'Failed to toggle availability');
    } catch (e) {
      return ApiResponse.error('Failed to toggle availability: $e');
    }
  }

  // Create bulk availability slots (for recurring schedules)
  Future<ApiResponse<List<AvailabilitySlot>>> createBulkAvailability({
    required List<DateTime> dates,
    required String startTime,
    required String endTime,
    bool isRecurring = false,
    String? recurringPattern,
  }) async {
    try {
      final response = await _apiService.post('/availability/bulk', data: {
        'dates': dates.map((date) => date.toIso8601String()).toList(),
        'startTime': startTime,
        'endTime': endTime,
        'isRecurring': isRecurring,
        'recurringPattern': recurringPattern,
      });

      if (response.success && response.data != null) {
        final slots = (response.data['slots'] as List)
            .map((slot) => AvailabilitySlot.fromJson(slot))
            .toList();
        return ApiResponse.success(slots);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to create bulk availability');
    } catch (e) {
      return ApiResponse.error('Failed to create bulk availability: $e');
    }
  }

  // Get booking requests for tutor
  Future<ApiResponse<List<BookingRequest>>> getBookingRequests() async {
    try {
      final response = await _apiService.get('/bookings/requests');

      if (response.success && response.data != null) {
        final requests = (response.data['requests'] as List)
            .map((request) => BookingRequest.fromJson(request))
            .toList();
        return ApiResponse.success(requests);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch booking requests');
    } catch (e) {
      return ApiResponse.error('Failed to fetch booking requests: $e');
    }
  }

  // Respond to a booking request
  Future<ApiResponse<bool>> respondToBookingRequest({
    required String requestId,
    required String response, // 'accept' or 'decline'
    String? message,
  }) async {
    try {
      final apiResponse = await _apiService.post('/bookings/requests/$requestId/respond', data: {
        'response': response,
        'message': message,
      });

      if (apiResponse.success) {
        return ApiResponse.success(true);
      }
      
      return ApiResponse.error(apiResponse.error ?? 'Failed to respond to booking request');
    } catch (e) {
      return ApiResponse.error('Failed to respond to booking request: $e');
    }
  }

  // Get tutor's upcoming sessions
  Future<ApiResponse<List<AvailabilitySlot>>> getUpcomingSessions() async {
    try {
      final response = await _apiService.get('/availability/upcoming-sessions');

      if (response.success && response.data != null) {
        final sessions = (response.data['sessions'] as List)
            .map((session) => AvailabilitySlot.fromJson(session))
            .toList();
        return ApiResponse.success(sessions);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch upcoming sessions');
    } catch (e) {
      return ApiResponse.error('Failed to fetch upcoming sessions: $e');
    }
  }

  // Mark session as completed
  Future<ApiResponse<bool>> markSessionCompleted({
    required String slotId,
    String? notes,
    int? rating,
  }) async {
    try {
      final response = await _apiService.post('/availability/slots/$slotId/complete', data: {
        'notes': notes,
        'rating': rating,
      });

      if (response.success) {
        return ApiResponse.success(true);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to mark session as completed');
    } catch (e) {
      return ApiResponse.error('Failed to mark session as completed: $e');
    }
  }

  // Cancel a session
  Future<ApiResponse<bool>> cancelSession({
    required String slotId,
    required String reason,
  }) async {
    try {
      final response = await _apiService.post('/availability/slots/$slotId/cancel', data: {
        'reason': reason,
      });

      if (response.success) {
        return ApiResponse.success(true);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to cancel session');
    } catch (e) {
      return ApiResponse.error('Failed to cancel session: $e');
    }
  }
}

class BookingRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String? studentPhone;
  final String slotId;
  final DateTime sessionDate;
  final TimeSlot timeSlot;
  final String subject;
  final String? message;
  final double amount;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime requestedAt;

  const BookingRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    this.studentPhone,
    required this.slotId,
    required this.sessionDate,
    required this.timeSlot,
    required this.subject,
    this.message,
    required this.amount,
    required this.status,
    required this.requestedAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    return BookingRequest(
      id: json['id'] ?? json['_id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      studentEmail: json['studentEmail'] ?? '',
      studentPhone: json['studentPhone'],
      slotId: json['slotId'] ?? '',
      sessionDate: DateTime.parse(json['sessionDate']),
      timeSlot: TimeSlot.fromJson(json['timeSlot']),
      subject: json['subject'] ?? '',
      message: json['message'],
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      requestedAt: DateTime.parse(json['requestedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'studentPhone': studentPhone,
      'slotId': slotId,
      'sessionDate': sessionDate.toIso8601String(),
      'timeSlot': timeSlot.toJson(),
      'subject': subject,
      'message': message,
      'amount': amount,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }
}