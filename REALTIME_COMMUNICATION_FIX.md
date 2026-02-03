# 🔴 CRITICAL: Real-Time Communication Fix

## Issues Found

### 1. Messages Not Appearing on Other Device
- Text, voice, and image messages don't automatically appear on the other device
- Socket.IO events are not properly synchronized

### 2. Calls Not Ringing on Other Device
- Video and voice calls don't trigger incoming call screen
- No notification or ring on the receiver's device

### 3. Root Causes

#### A. Socket Connection Issues
- Socket may not be connecting properly on physical devices
- Server URL might be incorrect for production
- Authentication token might not be passed correctly

#### B. Message Flow Broken
- Messages sent via HTTP API but socket events not emitted
- Server not broadcasting messages to other connected clients

#### C. Call Flow Broken
- Call initiation doesn't emit socket events
- Incoming call listener not properly set up

## Quick Diagnostic Steps

### Step 1: Check Socket Connection

On **BOTH devices**, after logging in, check the console logs:

**Expected logs:**
```
🔌 Attempting to connect to socket server: https://tutor-app-backend-wtru.onrender.com
🔌 Socket connected successfully
```

**If you see:**
```
❌ Socket connection error: ...
❌ No auth token found, cannot connect to socket
```
→ Socket is NOT connected!

### Step 2: Check Server Logs

On Render dashboard, check server logs for:

**Expected logs when user logs in:**
```
🔌 User connected: [Name] ([userId])
```

**If you DON'T see this** → Socket authentication is failing

### Step 3: Test Message Sending

Send a message from Device A, check console on Device B:

**Expected on Device B:**
```
💬 New message received: {...}
```

**If you DON'T see this** → Socket events not being broadcast

## Fixes Required

### Fix 1: Update Server Socket Handler

The server needs to properly broadcast messages to ALL connected clients in a conversation.

### Fix 2: Update Chat Controller

The chat controller needs to emit socket events when messages are sent via HTTP.

### Fix 3: Update Call Service

The call service needs to emit socket events for incoming calls.

### Fix 4: Ensure Socket Stays Connected

The mobile app needs to maintain socket connection even when app is in background.

## Testing Checklist

### Test 1: Socket Connection
- [ ] Device A: Login → Check console for "Socket connected"
- [ ] Device B: Login → Check console for "Socket connected"
- [ ] Server: Check logs for 2 "User connected" messages

### Test 2: Text Messages
- [ ] Device A: Send text message
- [ ] Device B: Message appears automatically (within 1-2 seconds)
- [ ] Device A: See message status change to "delivered"

### Test 3: Voice Messages
- [ ] Device A: Record and send voice message
- [ ] Device B: Voice message appears with play button
- [ ] Device B: Can play the voice message

### Test 4: Image Messages
- [ ] Device A: Send image
- [ ] Device B: Image appears automatically
- [ ] Device B: Can view full-size image

### Test 5: Video Call
- [ ] Device A: Initiate video call
- [ ] Device B: Incoming call screen appears
- [ ] Device B: Can accept/reject call
- [ ] Both: Video/audio works during call

### Test 6: Voice Call
- [ ] Device A: Initiate voice call
- [ ] Device B: Incoming call screen appears
- [ ] Device B: Can accept/reject call
- [ ] Both: Audio works during call

## Temporary Workaround

Until the fix is deployed, users can:

1. **For Messages**: Pull down to refresh the chat screen
2. **For Calls**: Manually check the call history screen

## Implementation Priority

1. **CRITICAL**: Fix socket message broadcasting (30 min)
2. **CRITICAL**: Fix call notifications (30 min)
3. **HIGH**: Add connection status indicator (15 min)
4. **MEDIUM**: Add retry logic for failed messages (20 min)

## Expected Behavior After Fix

### Messages
- ✅ Send message on Device A
- ✅ Appears on Device B within 1 second
- ✅ No need to refresh
- ✅ Works for text, voice, and images

### Calls
- ✅ Initiate call on Device A
- ✅ Device B shows incoming call screen immediately
- ✅ Ringtone plays on Device B
- ✅ Can accept/reject call
- ✅ Call connects successfully

### Status Indicators
- ✅ Green dot when user is online
- ✅ "Typing..." indicator when other user is typing
- ✅ Message status: Sent → Delivered → Read

## Next Steps

I will now implement the fixes in this order:

1. Update `server/controllers/chatController.js` to emit socket events
2. Update `server/controllers/callController.js` to emit socket events
3. Update `mobile_app/lib/core/services/socket_service.dart` to handle events
4. Update `mobile_app/lib/core/services/call_service.dart` to listen for calls
5. Test on both devices

## Files That Need Changes

### Server Side
- `server/controllers/chatController.js` - Add socket.emit for new messages
- `server/controllers/callController.js` - Add socket.emit for incoming calls
- `server/socket/socketHandler.js` - Ensure proper room management

### Mobile Side
- `mobile_app/lib/core/services/socket_service.dart` - Add missing event listeners
- `mobile_app/lib/core/services/call_service.dart` - Listen for incoming_call event
- `mobile_app/lib/core/services/chat_service.dart` - Handle socket events properly

## Debugging Commands

### Check if server is receiving socket connections:
```bash
# On Render dashboard, check logs for:
grep "User connected" logs
```

### Check if messages are being sent:
```bash
# On Render dashboard, check logs for:
grep "Message sent" logs
grep "new_message" logs
```

### Check mobile app socket status:
```dart
// Add this to your chat screen:
print('Socket connected: ${SocketService().isConnected}');
```
