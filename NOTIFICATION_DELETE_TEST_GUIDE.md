# Notification Delete Test Guide

## How to Test the Delete Functionality

### Step 1: Delete a Notification
1. Open the app and go to **Notifications** screen
2. **Slide a notification to the left** (swipe from right to left)
3. You should see a red "Delete" background
4. **Release** to delete
5. The notification should disappear with a "Notification deleted" message

### Step 2: Check Server Logs
Go to your Render dashboard and check the logs. You should see:
```
🗑️ Deleting notification: { notificationId: '...', userId: '...' }
✅ Notification deleted successfully: [notification-id]
```

If you see:
```
❌ Notification not found or not owned by user: [notification-id]
```
This means the notification doesn't exist or doesn't belong to the user.

### Step 3: Verify Deletion Persists
1. **Logout** from the app
2. **Login** again
3. Go to **Notifications** screen
4. **Check if the deleted notification is gone**

### Expected Result
✅ The deleted notification should NOT reappear after logout/login

### If Notification Reappears

This could mean:
1. **API call failed** - Check mobile app console for errors
2. **Network issue** - Delete request didn't reach server
3. **Wrong ID** - The notification ID being sent is incorrect

## Debugging Steps

### Check Mobile App Logs
When you delete a notification, check the console/logcat for:
```
Error deleting notification: [error message]
```

### Check Server Logs on Render
1. Go to https://dashboard.render.com
2. Select your service: `tutor-app-backend-wtru`
3. Click on **Logs** tab
4. Look for the delete notification logs when you swipe to delete

### Manual API Test
You can test the delete API directly using curl or Postman:

```bash
# Get your auth token first (from login)
TOKEN="your-jwt-token-here"

# Get notifications to find an ID
curl -X GET "https://tutor-app-backend-wtru.onrender.com/api/notifications" \
  -H "Authorization: Bearer $TOKEN"

# Delete a notification
curl -X DELETE "https://tutor-app-backend-wtru.onrender.com/api/notifications/[notification-id]" \
  -H "Authorization: Bearer $TOKEN"

# Check if it's gone
curl -X GET "https://tutor-app-backend-wtru.onrender.com/api/notifications" \
  -H "Authorization: Bearer $TOKEN"
```

## Common Issues

### Issue 1: "Failed to delete notification" Error
**Cause**: Network error or server issue
**Solution**: Check internet connection and server status

### Issue 2: Notification Reappears After Logout
**Cause**: Delete API call might be failing silently
**Solution**: 
1. Check mobile app logs for errors
2. Check server logs to see if delete request was received
3. Verify the notification ID is correct

### Issue 3: Can't Swipe to Delete
**Cause**: UI issue with Dismissible widget
**Solution**: This is a mobile app issue, not a server issue

## What's Been Fixed

✅ Delete route exists: `DELETE /api/notifications/:notificationId`
✅ Controller properly handles delete requests
✅ Service deletes from MongoDB database
✅ Mobile app calls the API correctly
✅ Enhanced logging added to track deletions

## Next Steps

1. **Test the delete functionality** following the steps above
2. **Check the server logs** to see if delete is being called
3. **Report back** with:
   - Did the notification disappear when you swiped?
   - Did you see the delete logs on the server?
   - Did the notification reappear after logout/login?
   - Any error messages in the app or server logs?

---

**The delete functionality is fully implemented and should work correctly.**
If it's not working, we need to see the logs to understand why.
