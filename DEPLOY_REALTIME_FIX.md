# 🚀 Deploy Real-Time Communication Fix

## Changes Made

### Server Side (3 files changed)

#### 1. `server/controllers/chatController.js`
**What changed:** Added Socket.IO event emission when messages are sent
**Why:** Messages were only saved to database but not broadcast to other connected clients

```javascript
// ✅ Now emits socket events to:
// - Recipient's user room: user_${recipientId}
// - Conversation room: chat_${conversationId}
```

#### 2. `server/controllers/callController.js`
**What changed:** Fixed Socket.IO room targeting for incoming calls
**Why:** Was emitting to wrong room format (receiverId instead of user_${receiverId})

```javascript
// ❌ Before: io.to(receiverId).emit('incoming_call', ...)
// ✅ After:  io.to(`user_${receiverId}`).emit('incoming_call', ...)
```

### Mobile Side (No changes needed)
- Socket service already properly configured
- Call service already listening for incoming_call events
- Chat service already listening for new_message events

## Deployment Steps

### Step 1: Deploy Server Changes to Render

```bash
# 1. Commit the changes
git add server/controllers/chatController.js
git add server/controllers/callController.js
git commit -m "Fix: Add Socket.IO events for real-time messaging and calls"

# 2. Push to GitHub (triggers auto-deploy on Render)
git push origin main
```

### Step 2: Wait for Render Deployment

1. Go to https://dashboard.render.com
2. Find your service: `tutor-app-backend`
3. Watch the deployment logs
4. Wait for "Deploy live" message (usually 2-3 minutes)

### Step 3: Verify Server is Running

```bash
# Check health endpoint
curl https://tutor-app-backend-wtru.onrender.com/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "...",
  "connectedUsers": 0
}
```

### Step 4: Test on Physical Devices

#### Test 1: Socket Connection
1. **Device A**: Login as student (etsebruk@example.com / 123abc)
2. **Device B**: Login as tutor (bubuam13@gmail.com / 123abc)
3. **Check logs**: Both should show "🔌 Socket connected successfully"

#### Test 2: Text Messages
1. **Device A**: Open chat with tutor
2. **Device A**: Send message "Hello from student"
3. **Device B**: Message should appear within 1-2 seconds
4. **Device B**: Reply "Hello from tutor"
5. **Device A**: Reply should appear within 1-2 seconds

#### Test 3: Voice Messages
1. **Device A**: Record and send voice message
2. **Device B**: Voice message should appear with play button
3. **Device B**: Tap play button - should play audio

#### Test 4: Image Messages
1. **Device A**: Send image from gallery
2. **Device B**: Image should appear automatically
3. **Device B**: Tap image - should open full screen

#### Test 5: Video Call
1. **Device A**: Tap video call button
2. **Device B**: Incoming call screen should appear immediately
3. **Device B**: Accept call
4. **Both**: Video and audio should work

#### Test 6: Voice Call
1. **Device A**: Tap voice call button
2. **Device B**: Incoming call screen should appear immediately
3. **Device B**: Accept call
4. **Both**: Audio should work

## Troubleshooting

### Issue: Messages still not appearing

**Check 1: Is Socket.IO connected?**
```
Look for: 🔌 Socket connected successfully
If not found: Socket connection failed
```

**Solution:**
- Check internet connection on both devices
- Restart the app on both devices
- Check Render logs for connection errors

**Check 2: Are socket events being emitted?**
On Render dashboard, check logs for:
```
💬 Socket event emitted to user_[userId]
💬 Socket event emitted to chat_[chatId]
```

If not found: Server code not deployed properly

**Solution:**
- Verify git push was successful
- Check Render deployment status
- Manually trigger redeploy on Render

### Issue: Calls still not ringing

**Check 1: Is incoming_call event being emitted?**
On Render dashboard, check logs for:
```
📞 Incoming call event emitted to user_[userId]
📞 Call data: {...}
```

If not found: Call controller not emitting events

**Solution:**
- Verify server deployment
- Check that io is available: `app.get('io')`

**Check 2: Is mobile app listening for incoming_call?**
On mobile device, check logs for:
```
📞 Incoming call received: {...}
```

If not found: Socket listener not set up

**Solution:**
- Restart the app
- Check that CallService.initialize() is called in main.dart

### Issue: Socket keeps disconnecting

**Possible causes:**
1. Network instability
2. Server timeout
3. Authentication token expired

**Solution:**
```dart
// Socket service has auto-reconnect enabled
// Check logs for:
🔌 Socket disconnected
🔌 Attempting to reconnect...
🔌 Socket connected successfully
```

If reconnection fails:
- Logout and login again (refreshes auth token)
- Check server is running on Render

## Verification Checklist

After deployment, verify these work:

### Real-Time Messaging
- [ ] Text messages appear instantly on other device
- [ ] Voice messages appear instantly on other device
- [ ] Image messages appear instantly on other device
- [ ] Typing indicator shows when other user is typing
- [ ] Online/offline status updates in real-time

### Real-Time Calls
- [ ] Video call triggers incoming call screen on other device
- [ ] Voice call triggers incoming call screen on other device
- [ ] Call can be accepted/rejected
- [ ] Video and audio work during call
- [ ] Call ends properly on both devices

### Status Indicators
- [ ] Green dot shows when user is online
- [ ] Message status: Sent → Delivered → Read
- [ ] Unread message count updates in real-time

## Expected Server Logs

When everything is working, you should see:

```
🔌 User connected: [Student Name] ([userId])
🔌 User connected: [Tutor Name] ([userId])
💬 User [Student Name] joined chat [chatId]
💬 User [Tutor Name] joined chat [chatId]
💬 Socket event emitted to user_[tutorId]
💬 Socket event emitted to chat_[chatId]
📞 Call initiated: video call from [studentId] to [tutorId]
📞 Incoming call event emitted to user_[tutorId]
```

## Rollback Plan

If issues occur after deployment:

### Option 1: Revert on Render
1. Go to Render dashboard
2. Find your service
3. Click "Manual Deploy"
4. Select previous successful deployment
5. Click "Deploy"

### Option 2: Revert Git Commit
```bash
git revert HEAD
git push origin main
```

## Performance Notes

- Socket.IO connections are lightweight
- Each user maintains 1 socket connection
- Messages are broadcast only to relevant users
- No performance impact expected

## Next Steps After Successful Deployment

1. Monitor Render logs for any errors
2. Test with multiple users simultaneously
3. Check message delivery rate (should be <1 second)
4. Verify call quality on different networks
5. Test with app in background/foreground

## Support

If issues persist after deployment:
1. Check Render logs for errors
2. Check mobile app logs for socket connection status
3. Verify both devices have internet connection
4. Try with different user accounts
5. Test on WiFi vs mobile data

## Success Criteria

✅ Messages appear on other device within 1 second
✅ Calls ring on other device immediately
✅ No need to refresh or pull-to-refresh
✅ Works consistently across multiple tests
✅ Works on both WiFi and mobile data
