import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/notification_service.dart';

class TutorNotificationsScreen extends StatefulWidget {
  const TutorNotificationsScreen({super.key});

  @override
  State<TutorNotificationsScreen> createState() => _TutorNotificationsScreenState();
}

class _TutorNotificationsScreenState extends State<TutorNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Refresh unread count
    _notificationService.refreshUnreadCount();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _notificationService.getNotifications();
      
      if (response.success && response.data != null) {
        setState(() {
          _notifications = response.data!;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to load notifications'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _notificationService.markAsRead(id);
      
      setState(() {
        final index = _notifications.indexWhere((n) => n['_id'] == id);
        if (index != -1) {
          _notifications[index]['read'] = true;
        }
      });
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    await _markAsRead(notification['_id']);
    
    // Navigate based on type
    final type = notification['type'] as String;
    switch (type) {
      case 'booking_request':
      case 'booking_accepted':
      case 'booking_declined':
      case 'booking_cancelled':
      case 'booking_reminder':
        context.go('/tutor-bookings');
        break;
      case 'new_message':
        context.go('/tutor-messages');
        break;
      case 'payment_received':
      case 'payment_pending':
        context.go('/tutor-earnings');
        break;
      default:
        break;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'booking_request':
        return Icons.calendar_today;
      case 'booking_accepted':
        return Icons.check_circle;
      case 'booking_declined':
      case 'booking_cancelled':
        return Icons.cancel;
      case 'booking_reminder':
        return Icons.alarm;
      case 'new_message':
        return Icons.message;
      case 'payment_received':
      case 'payment_pending':
        return Icons.payment;
      case 'profile_approved':
        return Icons.verified;
      case 'profile_rejected':
        return Icons.error;
      case 'system_announcement':
        return Icons.announcement;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'booking_request':
        return Colors.blue;
      case 'booking_accepted':
        return Colors.green;
      case 'booking_declined':
      case 'booking_cancelled':
        return Colors.red;
      case 'booking_reminder':
        return Colors.orange;
      case 'new_message':
        return Colors.purple;
      case 'payment_received':
        return Colors.green;
      case 'payment_pending':
        return Colors.orange;
      case 'profile_approved':
        return Colors.green;
      case 'profile_rejected':
        return Colors.red;
      case 'system_announcement':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return 'Recently';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 7) {
        return '${(difference.inDays / 7).floor()} week${difference.inDays > 13 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !(n['read'] ?? false)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () async {
                try {
                  await _notificationService.markAllAsRead();
                  setState(() {
                    for (var notification in _notifications) {
                      notification['read'] = true;
                    }
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error marking all as read: $e');
                }
              },
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationTile(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    final isRead = notification['read'] ?? false;
    final type = notification['type'] as String;
    final icon = _getIconForType(type);
    final color = _getColorForType(type);
    final title = notification['title'] ?? 'Notification';
    final body = notification['body'] ?? '';
    final time = _getTimeAgo(notification['createdAt']);
    
    return Dismissible(
      key: Key(notification['_id']),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingLG),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        try {
          await _notificationService.deleteNotification(notification['_id']);
          setState(() {
            _notifications.removeWhere((n) => n['_id'] == notification['_id']);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification deleted')),
            );
          }
        } catch (e) {
          print('Error deleting notification: $e');
        }
      },
      child: Container(
        color: isRead ? Colors.white : Colors.blue.shade50,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(body),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: !isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () => _handleNotificationTap(notification),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.spacingLG),
          Text(
            'No notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            'You\'re all caught up!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
