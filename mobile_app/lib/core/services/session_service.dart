import 'api_service.dart';

class SessionService {
  final ApiService _apiService = ApiService();

  // Start a session
  Future<ApiResponse<Map<String, dynamic>>> startSession(String bookingId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/sessions/$bookingId/start',
        data: {},
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to start session: $e');
    }
  }

  // Join an active session
  Future<ApiResponse<Map<String, dynamic>>> joinSession(String bookingId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/sessions/$bookingId/join',
        data: {},
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to join session: $e');
    }
  }

  // End a session
  Future<ApiResponse<Map<String, dynamic>>> endSession(
    String bookingId, {
    String? sessionNotes,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/sessions/$bookingId/end',
        data: {
          if (sessionNotes != null) 'sessionNotes': sessionNotes,
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to end session: $e');
    }
  }

  // Get session status
  Future<ApiResponse<Map<String, dynamic>>> getSessionStatus(String bookingId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/sessions/$bookingId/status',
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get session status: $e');
    }
  }

  // Check if session can start
  Future<bool> canStartSession(String bookingId) async {
    try {
      final response = await getSessionStatus(bookingId);
      if (response.success && response.data != null) {
        return response.data!['canStart'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking if session can start: $e');
      return false;
    }
  }

  // Check if session is active
  Future<bool> isSessionActive(String bookingId) async {
    try {
      final response = await getSessionStatus(bookingId);
      if (response.success && response.data != null) {
        final session = response.data!['session'] as Map<String, dynamic>?;
        return session?['isActive'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking if session is active: $e');
      return false;
    }
  }
}
