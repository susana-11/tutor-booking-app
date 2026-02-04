import 'api_service.dart';

class DashboardService {
  final ApiService _apiService = ApiService();

  // Get student dashboard data
  Future<ApiResponse<Map<String, dynamic>>> getStudentDashboard() async {
    try {
      final response = await _apiService.get('/dashboard/student');

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }

      return ApiResponse.error(response.error ?? 'Failed to load dashboard data');
    } catch (e) {
      return ApiResponse.error('Failed to load dashboard data: $e');
    }
  }

  // Get tutor dashboard data
  Future<ApiResponse<Map<String, dynamic>>> getTutorDashboard() async {
    try {
      final response = await _apiService.get('/dashboard/tutor');

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }

      return ApiResponse.error(response.error ?? 'Failed to load dashboard data');
    } catch (e) {
      return ApiResponse.error('Failed to load dashboard data: $e');
    }
  }
}
