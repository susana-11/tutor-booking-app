import 'dart:async';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();
  
  // Stream controller for notification count updates
  final _notificationCountController = StreamController<int>.broadcast();
  Stream<int> get notificationCountStream => _notificationCountController.stream;
  
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  
  // Fetch notifications
  Future<ApiResponse<List<Map<String, dynamic>>>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (unreadOnly) 'unreadOnly': 'true',
      };
      
      final response = await _apiService.get(
        '/notifications',
        queryParameters: queryParams,
      );
      
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final notifications = (data['notifications'] as List?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ?? [];
        
        // Update unread count
        _unreadCount = data['unreadCount'] ?? 0;
        _notificationCountController.add(_unreadCount);
        
        return ApiResponse.success(notifications);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch notifications');
    } catch (e) {
      return ApiResponse.error('Failed to fetch notifications: $e');
    }
  }
  
  // Get unread count
  Future<int> getUnreadCount() async {
    try {
      print('📊 Fetching unread count from server...');
      final response = await _apiService.get('/notifications/unread-count');
      
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _unreadCount = data['count'] ?? 0;
        print('✅ Unread count updated: $_unreadCount');
        _notificationCountController.add(_unreadCount);
        return _unreadCount;
      }
      
      print('❌ Failed to get unread count');
      return 0;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }
  
  // Refresh unread count
  Future<void> refreshUnreadCount() async {
    await getUnreadCount();
  }
  
  // Mark notification as read
  Future<ApiResponse<void>> markAsRead(String notificationId) async {
    try {
      print('📧 Marking notification as read: $notificationId');
      print('📊 Current unread count: $_unreadCount');
      
      final response = await _apiService.put<void>(
        '/notifications/$notificationId/read',
        data: {},
      );
      
      if (response.success) {
        print('✅ Notification marked as read successfully');
        // Don't decrement locally - let refreshUnreadCount handle it
        // This ensures we get the accurate count from server
      } else {
        print('❌ Failed to mark as read: ${response.error}');
      }
      
      return response;
    } catch (e) {
      print('❌ Error marking as read: $e');
      return ApiResponse.error('Failed to mark notification as read: $e');
    }
  }
  
  // Mark all notifications as read
  Future<ApiResponse<void>> markAllAsRead() async {
    try {
      print('📧 Marking all notifications as read...');
      print('📊 Current unread count: $_unreadCount');
      
      final response = await _apiService.put<void>(
        '/notifications/read-all',
        data: {},
      );
      
      if (response.success) {
        print('✅ All notifications marked as read on server');
        _unreadCount = 0;
        _notificationCountController.add(_unreadCount);
        print('📊 Updated unread count to: $_unreadCount');
        print('📡 Broadcasted count update to stream');
      } else {
        print('❌ Failed to mark all as read: ${response.error}');
      }
      
      return response;
    } catch (e) {
      print('❌ Error marking all as read: $e');
      return ApiResponse.error('Failed to mark all notifications as read: $e');
    }
  }
  
  // Delete notification
  Future<ApiResponse<void>> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.delete(
        '/notifications/$notificationId',
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to delete notification: $e');
    }
  }
  
  // Dispose
  void dispose() {
    _notificationCountController.close();
  }
}
