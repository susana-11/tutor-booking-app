# Notification System Guide

## Overview
The tutor booking app includes a complete real-time notification system that supports:
- **Real-time notifications** via Socket.IO (always enabled)
- **Push notifications** via Firebase Cloud Messaging (optional, requires setup)
- **In-app notification center** with read/unread status
- **Multi-device support** for push notifications

## Architecture

### Backend Components

1. **Notification Model** (`server/models/Notification.js`)
   - Stores all notifications in MongoDB
   - Tracks read/unread status
   - Auto-expires after 30 days
   - Supports different notification types and priorities

2. **Device Token Model** (`server/models/DeviceToken.js`)
   - Manages FCM tokens for push notifications
   - Supports multiple devices per user
   - Tracks active/inactive tokens

3. **Notification Service** (`server/services/notificationService.js`)
   - Central service for all notification operations
   - Handles both Socket.IO and FCM delivery
   - Provides methods for all notification types
   - Gracefully degrades if Firebase is not configured

4. **Notification Controller** (`server/controllers/notificationController.js`)
   - REST API endpoints for notification management
   - Device token registration/unregistration

5. **Notification Routes** (`server/routes/notifications.js`)
   - GET `/api/notifications` - Get user notifications
   - PUT `/api/notifications/:id/read` - Mark as read
   - PUT `/api/notifications/read-all` - Mark all as read
   - DELETE `/api/notifications/:id` - Delete notification
   - POST `/api/notifications/device-token` - Register FCM token
   - DELETE `/api/notifications/device-token` - Unregister FCM token

### Notification Types

The system supports the following notification types:

#### Booking Notifications
- `booking_request` - New booking request for tutor
- `booking_accepted` - Booking accepted by tutor
- `booking_declined` - Booking declined by tutor
- `booking_cancelled` - Booking cancelled by either party
- `booking_reminder` - Reminder before session starts

#### Communication Notifications
- `new_message` - New chat message received
- `call_incoming` - Incoming voice/video call
- `call_missed` - Missed call notification

#### Payment Notifications
- `payment_received` - Payment received for session
- `payment_pending` - Payment pending reminder

#### Profile Notifications
- `profile_approved` - Tutor profile approved by admin
- `profile_rejected` - Tutor profile needs updates

#### System Notifications
- `system_announcement` - System-wide announcements

### Priority Levels
- `urgent` - Incoming calls (highest priority)
- `high` - Booking requests, acceptances, profile updates
- `normal` - Messages, cancellations, reminders
- `low` - General announcements

## Backend Setup

### 1. Install Dependencies
Already installed: `firebase-admin` package

### 2. Configure Firebase (Optional)

#### Option A: Without Firebase (Socket.IO only)
No configuration needed! Notifications will work via Socket.IO for real-time delivery.

#### Option B: With Firebase (Full push notification support)

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use existing one
   - Enable Cloud Messaging

2. **Generate Service Account Key**
   - Go to Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Download the JSON file

3. **Add to Environment Variables**
   ```bash
   # In server/.env file
   FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"your-project-id",...}
   ```
   
   **Important**: Convert the entire JSON file to a single-line string

4. **Restart Server**
   The server will automatically initialize Firebase on startup

### 3. Integration in Controllers

Notifications are already integrated in:
- `bookingController.js` - Booking events
- Ready for integration in:
  - `chatController.js` - Message events
  - `callController.js` - Call events
  - `adminController.js` - Profile approval events

Example usage:
```javascript
const notificationService = require('../services/notificationService');

// Send booking request notification
await notificationService.notifyBookingRequest({
  tutorId: '123',
  studentName: 'John Doe',
  subject: 'Mathematics',
  date: 'Feb 5, 2026',
  time: '10:00 - 11:00',
  bookingId: 'booking123'
});
```

## Mobile App Setup (Flutter)

### 1. Add Dependencies

Add to `mobile_app/pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
```

### 2. Configure Firebase

#### Android Setup
1. Download `google-services.json` from Firebase Console
2. Place in `mobile_app/android/app/`
3. Update `android/build.gradle`:
   ```gradle
   dependencies {
     classpath 'com.google.gms:google-services:4.4.0'
   }
   ```
4. Update `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

#### iOS Setup
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place in `mobile_app/ios/Runner/`
3. Update `ios/Podfile`:
   ```ruby
   platform :ios, '12.0'
   ```

### 3. Create Notification Service

Create `mobile_app/lib/core/services/notification_service.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService;

  NotificationService(this._apiService);

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _registerToken(token);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_registerToken);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    }

    // Initialize local notifications
    await _initializeLocalNotifications();
  }

  Future<void> _registerToken(String token) async {
    try {
      await _apiService.post('/notifications/device-token', {
        'token': token,
        'platform': 'android', // or 'ios'
        'deviceId': 'device-id',
        'deviceName': 'Device Name',
        'appVersion': '1.0.0',
      });
    } catch (e) {
      print('Failed to register FCM token: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification when app is in foreground
    _showLocalNotification(
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      message.data,
    );
  }

  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'default',
      'Default',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: data.toString(),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigate based on notification type
    final type = message.data['type'];
    // Implement navigation logic
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle local notification tap
  }
}

// Background message handler (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}
```

### 4. Initialize in Main

Update `mobile_app/lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize notification service
  final apiService = ApiService();
  final notificationService = NotificationService(apiService);
  await notificationService.initialize();
  
  runApp(MyApp());
}
```

### 5. Socket.IO Notifications

Update `mobile_app/lib/core/services/socket_service.dart`:

```dart
void _setupNotificationListener() {
  _socket?.on('notification', (data) {
    print('📬 Received notification: $data');
    
    // Show local notification
    _showLocalNotification(
      data['title'] ?? 'New Notification',
      data['body'] ?? '',
      data,
    );
    
    // Update notification badge/count
    _updateNotificationBadge();
  });
}
```

### 6. Create Notification Screen

Create `mobile_app/lib/features/notifications/screens/notifications_screen.dart`:

```dart
class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Notification> _notifications = [];
  bool _loading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await ApiService().get('/notifications');
      setState(() {
        _notifications = (response['data']['notifications'] as List)
            .map((n) => Notification.fromJson(n))
            .toList();
        _unreadCount = response['data']['unreadCount'];
        _loading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await ApiService().put('/notifications/$notificationId/read');
      _loadNotifications();
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiService().put('/notifications/read-all');
      _loadNotifications();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text('Mark all read'),
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return NotificationTile(
                      notification: notification,
                      onTap: () => _markAsRead(notification.id),
                    );
                  },
                ),
    );
  }
}
```

## Testing

### 1. Test Without Firebase (Socket.IO only)
1. Start the server
2. Login to mobile app
3. Create a booking request
4. Check if tutor receives real-time notification via Socket.IO

### 2. Test With Firebase (Full push notifications)
1. Configure Firebase as described above
2. Register device token on app startup
3. Close the app completely
4. Create a booking request from another device
5. Check if push notification appears

### 3. Test Notification Center
1. Open notifications screen in app
2. Verify all notifications are listed
3. Test mark as read functionality
4. Test delete functionality

## Notification Flow

### Booking Request Flow
1. Student creates booking → `bookingController.createBookingRequest()`
2. Server calls `notificationService.notifyBookingRequest()`
3. Notification saved to database
4. Push notification sent via FCM (if configured)
5. Real-time notification sent via Socket.IO
6. Tutor receives notification in app

### Booking Response Flow
1. Tutor accepts/declines → `bookingController.respondToBookingRequest()`
2. Server calls `notificationService.notifyBookingAccepted()` or `notifyBookingDeclined()`
3. Student receives notification

### Cancellation Flow
1. User cancels booking → `bookingController.cancelBooking()`
2. Server calls `notificationService.notifyBookingCancelled()`
3. Other party receives notification

## Best Practices

1. **Always wrap notification calls in try-catch**
   - Don't let notification failures break main functionality

2. **Use appropriate priority levels**
   - `urgent` for time-sensitive actions (calls)
   - `high` for important updates (bookings)
   - `normal` for general notifications

3. **Include actionUrl for deep linking**
   - Helps users navigate to relevant screens

4. **Clean up old notifications**
   - Auto-expiry is set to 30 days
   - Users can manually delete notifications

5. **Handle token refresh**
   - FCM tokens can change, always listen for updates

6. **Test both online and offline scenarios**
   - Notifications should queue when offline
   - Deliver when connection restored

## Troubleshooting

### Push notifications not working
- Check Firebase configuration
- Verify FCM token is registered
- Check server logs for Firebase errors
- Ensure app has notification permissions

### Socket.IO notifications not working
- Check if user is connected to Socket.IO
- Verify `global.io` is set in server.js
- Check socket room joining logic

### Notifications not appearing in app
- Check API endpoint responses
- Verify authentication token
- Check notification model schema

## Future Enhancements

1. **Notification preferences**
   - Allow users to customize notification types
   - Quiet hours support

2. **Rich notifications**
   - Images, action buttons
   - Inline replies

3. **Notification grouping**
   - Group similar notifications
   - Summary notifications

4. **Analytics**
   - Track notification delivery rates
   - Monitor engagement metrics
