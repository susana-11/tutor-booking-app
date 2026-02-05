import 'api_service.dart';

class EarningsAnalyticsService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getEarningsAnalytics() async {
    try {
      final response = await _apiService.get('/dashboard/tutor/earnings-analytics');
      
      if (response.success && response.data != null) {
        return {
          'success': true,
          'data': response.data,
        };
      }
      
      return {
        'success': false,
        'error': response.message ?? 'Failed to load analytics',
      };
    } catch (e) {
      print('Get earnings analytics error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
