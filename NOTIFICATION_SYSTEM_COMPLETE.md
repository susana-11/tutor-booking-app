# Notification System - Complete Implementation

## Overview
The notification system has been fully implemented with real data from the backend and functional notification counts.

## What Was Implemented

### 1. Mobile App - Notification Service
**File:** `mobile_app/lib/core/services/notification_service.dart`

Features:
- Fetch notifications from backend
- Get unread notification count
- Mark individual notifications as read
- Mark all notifications as read
- Delete notifications
- Real-time notification count updates via Stream

### 2. Updated Notification Screens

#### Student Notifications
**File:** `mobile_app/lib/features/student/screens/student_notifications_screen.dart`

Changes:
- Replaced placeholder data with real API calls
- Added loading states
- Pull-to-refresh functionality
- Dynamic icon and color based on notification type
- Time ago formatting
- Proper navigation based on notification type

#### Tutor Notifications
**File:** `mobile_app/lib/features/tutor/screens/tutor_notifications_screen.dart`

Changes:
- Same improvements as student notifications
- Tutor-specific navigation routes

### 3. Dashboard Notification Badges

#### Student Dashboard
**File:** `mobile_app/lib/features/student/screens/student_dashboard_screen.dart`

Changes:
- Real-time notification count badge
- Listens to notification count stream
- Shows count only when > 0
- Displays "99+" for counts over 99

#### Tutor Dashboard
**File:** `mobile_app/lib/features/tutor/screens/tutor_dashboard_screen.dart`

Changes:
- Same notification badge improvements
- Real-time updates

### 4. Backend Test Script
**File:** `server/scripts/createTestNotifications.js`

Purpose:
- Creates sample notifications for testing
- Generates notifications for both students and tutors
- Various notification types

## Notification Types

The system supports the following notification types:

### Booking Related
- `booking_request` - New booking request (tutor)
- `booking_accepted` - Booking confirmed (student)
- `booking_declined` - Booking declined (student)
- `booking_cancelled` - Booking cancelled (both)
- `booking_reminder` - Session reminder (both)

### Communication
- `new_message` - New chat message
- `call_incoming` - Incoming call
- `call_missed` - Missed call

### Payment
- `payment_received` - Payment received (tutor)
- `payment_pending` - Payment pending

### Profile
- `profile_approved` - Profile approved (tutor)
- `profile_rejected` - Profile needs updates (tutor)

### System
- `system_announcement` - System-wide announcements

## API Endpoints

All endpoints require authentication.

### Get Notifications
```
GET /api/notifications
Query Parameters:
  - page: number (default: 1)
  - limit: number (default: 20)
  - unreadOnly: boolean (default: false)

Response:
{
  "success": true,
  "data": {
    "notifications": [...],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 50,
      "pages": 3
    },
    "unreadCount": 5
  }
}
```

### Mark as Read
```
PUT /api/notifications/:notificationId/read

Response:
{
  "success": true,
  "message": "Notification marked as read"
}
```

### Mark All as Read
```
PUT /api/notifications/read-all

Response:
{
  "success": true,
  "message": "All notifications marked as read"
}
```

### Delete Notification
```
DELETE /api/notifications/:notificationId

Response:
{
  "success": true,
  "message": "Notification deleted"
}
```

## How to Test

### 1. Create Test Notifications
```bash
cd server
node scripts/createTestNotifications.js
```

This will create sample notifications for existing users.

### 2. View in Mobile App
1. Login as a student or tutor
2. Check the notification badge on the dashboard
3. Tap the notification icon to view all notifications
4. Tap a notification to navigate to the relevant screen
5. Swipe left to delete a notification
6. Use "Mark all read" to clear all unread notifications

### 3. Real-time Updates
- Notification count updates automatically when:
  - New notifications are received
  - Notifications are marked as read
  - Notifications are deleted

## Features

### Visual Indicators
- **Unread Badge**: Red dot on notification icon
- **Unread Count**: Number badge on dashboard
- **Unread Highlight**: Blue background for unread notifications
- **Type-based Icons**: Different icons for each notification type
- **Type-based Colors**: Color-coded by notification type

### User Actions
- **Tap**: Mark as read and navigate to relevant screen
- **Swipe Left**: Delete notification
- **Pull Down**: Refresh notifications
- **Mark All Read**: Clear all unread notifications at once

### Navigation
Notifications navigate to appropriate screens based on type:
- Booking notifications → Bookings screen
- Message notifications → Messages screen
- Payment notifications → Earnings screen (tutor) or Bookings (student)
- Profile notifications → Profile screen

## Backend Integration

### Automatic Notifications
The system automatically creates notifications for:
- New booking requests
- Booking status changes (accepted, declined, cancelled)
- Session reminders (24h, 1h, 15min before)
- New messages
- Payment events
- Profile approval/rejection

### Socket.IO Integration
Real-time notifications are sent via Socket.IO when:
- A new notification is created
- User joins their room: `user_${userId}`

### Push Notifications (Optional)
If Firebase is configured:
- Push notifications are sent to user devices
- Device tokens are managed automatically
- Failed tokens are deactivated

## Database Schema

### Notification Model
```javascript
{
  userId: ObjectId,           // User receiving the notification
  type: String,               // Notification type
  title: String,              // Notification title
  body: String,               // Notification message
  data: Object,               // Additional data
  read: Boolean,              // Read status
  readAt: Date,               // When marked as read
  priority: String,           // low, normal, high, urgent
  actionUrl: String,          // Deep link URL
  imageUrl: String,           // Optional image
  expiresAt: Date,            // Optional expiration
  createdAt: Date,            // Auto-generated
  updatedAt: Date             // Auto-generated
}
```

### Indexes
- `{ userId: 1, read: 1, createdAt: -1 }` - For efficient queries
- `{ createdAt: 1 }` - TTL index (auto-delete after 30 days)

## Performance Considerations

### Pagination
- Default limit: 20 notifications per page
- Prevents loading too much data at once

### Auto-deletion
- Notifications older than 30 days are automatically deleted
- Keeps database size manageable

### Efficient Queries
- Indexed queries for fast retrieval
- Separate unread count query

### Stream Updates
- Notification count updates via Stream
- No need to poll the server

## Troubleshooting

### Notifications Not Showing
1. Check if user is authenticated
2. Verify backend is running
3. Check network connectivity
4. Look for errors in console

### Count Not Updating
1. Ensure notification service is initialized
2. Check if stream is being listened to
3. Verify backend returns unreadCount

### Navigation Not Working
1. Check route names match app router
2. Verify GoRouter configuration
3. Check notification type mapping

## Future Enhancements

### Possible Improvements
1. **Notification Preferences**: Let users choose which notifications to receive
2. **Notification Grouping**: Group similar notifications
3. **Rich Notifications**: Add images and action buttons
4. **Notification History**: Archive old notifications
5. **Sound/Vibration**: Customize notification alerts
6. **In-app Notification Banner**: Show notifications while app is open
7. **Notification Categories**: Filter by category
8. **Scheduled Notifications**: Send at specific times

## Summary

The notification system is now fully functional with:
- ✅ Real data from backend
- ✅ Functional notification counts
- ✅ Real-time updates
- ✅ Proper navigation
- ✅ Mark as read functionality
- ✅ Delete functionality
- ✅ Pull-to-refresh
- ✅ Type-based styling
- ✅ Time ago formatting
- ✅ Dashboard badges
- ✅ Test script for development

Users can now receive, view, and manage notifications throughout the app!
