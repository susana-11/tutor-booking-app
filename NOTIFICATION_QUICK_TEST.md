# Quick Test Guide - Notification System

## Step-by-Step Testing

### 1. Start the Backend Server
```bash
cd server
npm start
```

### 2. Create Test Notifications
In a new terminal:
```bash
cd server
node scripts/createTestNotifications.js
```

This will create sample notifications for existing users.

### 3. Test in Mobile App

#### For Students:
1. Login as a student
2. Look at the dashboard - you should see a red badge with a number on the notification icon
3. Tap the notification icon
4. You should see 3 test notifications:
   - Booking Confirmed
   - New Message
   - Session Reminder
5. Try these actions:
   - **Tap a notification** → It marks as read and navigates to the relevant screen
   - **Swipe left** → Deletes the notification
   - **Pull down** → Refreshes the list
   - **Tap "Mark all read"** → Marks all as read

#### For Tutors:
1. Login as a tutor
2. Look at the dashboard - you should see a red badge with a number
3. Tap the notification icon
4. You should see 4 test notifications:
   - New Booking Request
   - Payment Received
   - New Message
   - Session Reminder
5. Test the same actions as above

### 4. Verify Real-time Updates

#### Test Notification Count:
1. Open the app and note the notification count
2. Tap a notification to mark it as read
3. Go back to dashboard
4. The count should decrease by 1

#### Test Mark All Read:
1. Open notifications screen
2. Tap "Mark all read"
3. Go back to dashboard
4. The notification badge should disappear

#### Test Delete:
1. Open notifications screen
2. Swipe left on a notification
3. Tap delete
4. The notification should be removed
5. Go back to dashboard
6. The count should update

### 5. Test Navigation

Each notification type navigates to a different screen:

**Student Notifications:**
- Booking notifications → `/student-bookings`
- Message notifications → `/student-messages`

**Tutor Notifications:**
- Booking notifications → `/tutor-bookings`
- Payment notifications → `/tutor-earnings`
- Message notifications → `/tutor-messages`

### 6. Test Real Notifications

To test with real notifications, perform these actions:

#### Create a Booking:
1. Login as student
2. Search for a tutor
3. Book a session
4. Login as tutor
5. Check notifications - should see "New Booking Request"

#### Accept a Booking:
1. Login as tutor
2. Go to bookings
3. Accept a pending booking
4. Login as student
5. Check notifications - should see "Booking Confirmed"

#### Send a Message:
1. Login as student
2. Go to messages
3. Send a message to a tutor
4. Login as tutor
5. Check notifications - should see "New Message"

## Expected Behavior

### Notification Badge
- Shows on dashboard when there are unread notifications
- Displays the count (e.g., "3")
- Shows "99+" for counts over 99
- Disappears when all notifications are read

### Notification List
- Shows most recent first
- Unread notifications have blue background
- Read notifications have white background
- Each notification shows:
  - Icon (based on type)
  - Title
  - Message
  - Time ago (e.g., "2 hours ago")
  - Blue dot for unread

### Actions
- **Tap**: Marks as read and navigates
- **Swipe left**: Shows delete button
- **Pull down**: Refreshes list
- **Mark all read**: Clears all unread

### Loading States
- Shows spinner while loading
- Shows "No notifications" when empty
- Shows error message if API fails

## Troubleshooting

### No Notifications Showing
**Problem**: Notification list is empty
**Solution**: 
1. Run the test script: `node scripts/createTestNotifications.js`
2. Check if user is logged in
3. Verify backend is running

### Count Not Updating
**Problem**: Badge count doesn't change
**Solution**:
1. Pull down to refresh
2. Restart the app
3. Check console for errors

### Navigation Not Working
**Problem**: Tapping notification doesn't navigate
**Solution**:
1. Check if routes are configured in app router
2. Verify notification type is recognized
3. Check console for navigation errors

### Can't Delete Notifications
**Problem**: Swipe to delete doesn't work
**Solution**:
1. Make sure you're swiping from right to left
2. Check if backend is running
3. Verify authentication token is valid

## API Testing with Postman/cURL

### Get Notifications
```bash
curl -X GET http://localhost:5000/api/notifications \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Mark as Read
```bash
curl -X PUT http://localhost:5000/api/notifications/NOTIFICATION_ID/read \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Mark All as Read
```bash
curl -X PUT http://localhost:5000/api/notifications/read-all \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Delete Notification
```bash
curl -X DELETE http://localhost:5000/api/notifications/NOTIFICATION_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Success Criteria

✅ Notification badge shows correct count
✅ Tapping notification marks it as read
✅ Tapping notification navigates to correct screen
✅ Swipe to delete works
✅ Mark all read clears badge
✅ Pull to refresh updates list
✅ Time ago displays correctly
✅ Icons and colors match notification type
✅ Loading states work properly
✅ Empty state shows when no notifications

## Next Steps

After testing, you can:
1. Customize notification types
2. Add more notification triggers
3. Implement push notifications (requires Firebase)
4. Add notification preferences
5. Implement notification grouping
