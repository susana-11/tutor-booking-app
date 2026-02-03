# Notification System - Quick Start

## What's Implemented ✅

The notification system is **fully functional on the backend** and ready to use!

### Backend (100% Complete)
- ✅ Real-time notifications via Socket.IO
- ✅ Push notifications via Firebase (optional)
- ✅ Notification database storage
- ✅ REST API endpoints
- ✅ Integrated into booking flow
- ✅ Multi-device support
- ✅ Auto-cleanup after 30 days

### Current Notification Types
1. **Booking Request** - Tutor receives notification when student books
2. **Booking Accepted** - Student receives notification when tutor accepts
3. **Booking Declined** - Student receives notification when tutor declines
4. **Booking Cancelled** - Both parties notified on cancellation

## How It Works Right Now

### 1. Real-time Notifications (Socket.IO) - ACTIVE ✅
When a booking event happens:
1. Notification saved to database
2. Real-time notification sent via Socket.IO
3. User receives notification instantly (if connected)

**No configuration needed!** This works out of the box.

### 2. Push Notifications (Firebase) - OPTIONAL ⏳
For notifications when app is closed:
1. Requires Firebase setup
2. Requires mobile app implementation
3. See `NOTIFICATION_SYSTEM_GUIDE.md` for setup

## Testing the System

### Test 1: Via Booking Flow (Recommended)
1. Start the server: `cd server && npm start`
2. Open mobile app as Student
3. Create a booking request
4. Open mobile app as Tutor (different device/emulator)
5. Tutor should receive notification via Socket.IO
6. Accept/decline the booking
7. Student should receive notification

### Test 2: Via Test Script
```bash
cd server
node scripts/testNotifications.js
```

This will:
- Create test notifications
- Verify database storage
- Test all notification methods
- Show system status

### Test 3: Via API (Postman/curl)
```bash
# Get notifications (requires auth token)
GET http://localhost:5000/api/notifications

# Mark as read
PUT http://localhost:5000/api/notifications/:id/read

# Delete notification
DELETE http://localhost:5000/api/notifications/:id
```

## API Endpoints

All endpoints require authentication (Bearer token).

### Get Notifications
```
GET /api/notifications?page=1&limit=20&unreadOnly=false
```

Response:
```json
{
  "success": true,
  "data": {
    "notifications": [...],
    "pagination": { "page": 1, "limit": 20, "total": 5, "pages": 1 },
    "unreadCount": 3
  }
}
```

### Mark as Read
```
PUT /api/notifications/:notificationId/read
```

### Mark All as Read
```
PUT /api/notifications/read-all
```

### Delete Notification
```
DELETE /api/notifications/:notificationId
```

### Register Device Token (for push notifications)
```
POST /api/notifications/device-token
Body: {
  "token": "fcm_token_here",
  "platform": "android",
  "deviceId": "device_id",
  "deviceName": "Device Name",
  "appVersion": "1.0.0"
}
```

## Current Booking Flow with Notifications

### Student Creates Booking
1. Student submits booking request
2. ✅ **Notification sent to Tutor**
   - Type: `booking_request`
   - Priority: `high`
   - Title: "New Booking Request"
   - Body: "John Doe wants to book a Mathematics session..."

### Tutor Accepts Booking
1. Tutor clicks Accept
2. ✅ **Notification sent to Student**
   - Type: `booking_accepted`
   - Priority: `high`
   - Title: "Booking Confirmed! 🎉"
   - Body: "Jane Smith accepted your Mathematics session..."

### Tutor Declines Booking
1. Tutor clicks Decline
2. ✅ **Notification sent to Student**
   - Type: `booking_declined`
   - Priority: `normal`
   - Title: "Booking Declined"
   - Body: "Jane Smith declined your Mathematics session..."

### Either Party Cancels
1. User cancels booking
2. ✅ **Notification sent to Other Party**
   - Type: `booking_cancelled`
   - Priority: `normal`
   - Title: "Booking Cancelled"
   - Body: "Your Mathematics session was cancelled..."

## Checking Notifications in Database

```javascript
// Connect to MongoDB
use tutor-booking

// View all notifications
db.notifications.find().pretty()

// View unread notifications for a user
db.notifications.find({ 
  userId: ObjectId("user_id_here"), 
  read: false 
}).pretty()

// Count notifications by type
db.notifications.aggregate([
  { $group: { _id: "$type", count: { $sum: 1 } } }
])
```

## Server Logs

When notifications are sent, you'll see logs like:
```
✅ Push notification sent: 0/0 successful (Firebase not configured)
📬 Real-time notification sent via Socket.IO to user_123
```

## What's Next?

### To Enable Push Notifications:
1. Set up Firebase project
2. Add `FIREBASE_SERVICE_ACCOUNT` to `.env`
3. Implement mobile app notification service
4. See `NOTIFICATION_SYSTEM_GUIDE.md` for details

### To Add More Notification Types:
1. Add notification type to `Notification` model enum
2. Create method in `notificationService.js`
3. Call method from appropriate controller
4. Example: Chat messages, call notifications, etc.

### To Customize Notifications:
Edit `server/services/notificationService.js`:
- Change notification titles/bodies
- Adjust priority levels
- Add custom data fields
- Modify delivery logic

## Troubleshooting

### "Firebase credentials not found"
- This is normal! Push notifications are optional
- Socket.IO notifications still work
- Add Firebase config to enable push notifications

### "Notification not received"
- Check if user is connected to Socket.IO
- Check server logs for errors
- Verify notification was created in database
- Check user ID matches

### "Cannot read property 'emit' of undefined"
- Ensure `global.io` is set in `server.js`
- Restart the server

## Files to Review

### Backend Implementation
- `server/models/Notification.js` - Notification schema
- `server/services/notificationService.js` - Core notification logic
- `server/controllers/notificationController.js` - API endpoints
- `server/routes/notifications.js` - Routes
- `server/controllers/bookingController.js` - Integration example

### Documentation
- `NOTIFICATION_SYSTEM_GUIDE.md` - Complete guide
- `NOTIFICATION_IMPLEMENTATION_STATUS.md` - Status tracker
- `server/.env.example` - Configuration template

## Support

For detailed implementation instructions, see:
- **Backend Setup**: `NOTIFICATION_SYSTEM_GUIDE.md` (Backend Setup section)
- **Mobile App Setup**: `NOTIFICATION_SYSTEM_GUIDE.md` (Mobile App Setup section)
- **Testing**: `NOTIFICATION_SYSTEM_GUIDE.md` (Testing section)
- **Troubleshooting**: `NOTIFICATION_SYSTEM_GUIDE.md` (Troubleshooting section)

---

**Status**: Backend is production-ready! Mobile app implementation pending.
