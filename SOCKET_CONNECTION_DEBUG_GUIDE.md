# 🔍 Socket.IO Connection Debug Guide

## 🎯 GOAL
Get the mobile app to successfully connect to Socket.IO server on Render.

## 📋 WHAT WE CHANGED

### 1. Enhanced Socket Service Logging (`mobile_app/lib/core/services/socket_service.dart`)
- ✅ Added detailed connection attempt logging
- ✅ Added auth token verification logging
- ✅ Added connection success/failure logging
- ✅ Added all Socket.IO lifecycle event logging
- ✅ Added incoming call event logging

### 2. Enhanced App Initialization (`mobile_app/lib/main.dart`)
- ✅ Added service initialization logging
- ✅ Added connection status check after 2 seconds
- ✅ Added warning if socket fails to connect

## 🔧 TESTING STEPS

### Step 1: Rebuild the App
```bash
cd mobile_app
flutter clean
flutter pub get
flutter build apk --release
```

### Step 2: Install on BOTH Devices
- Uninstall old app completely
- Install new APK on both devices
- This ensures fresh start with new logging

### Step 3: Login on Both Devices
- Device 1: Login as tutor (`bubuam13@gmail.com` / `123abc`)
- Device 2: Login as student (`etsebruk@example.com` / `123abc`)

### Step 4: Check App Logs Immediately After Login

**Look for these messages in the app console:**

✅ **SUCCESS - You should see:**
```
🚀 Initializing app services...
🔌 Connecting to Socket.IO...
✅ Auth token found: eyJhbGciOiJIUzI1NiIs...
🔌 Socket server URL: https://tutor-app-backend-wtru.onrender.com
🔌 Attempting to connect to socket server...
🔌 Socket instance created, waiting for connection...
✅ Socket event handlers registered
✅✅✅ Socket connected successfully! ✅✅✅
🔌 Socket ID: abc123xyz
✅ Socket.IO connected successfully!
💬 Initializing chat service...
📞 Initializing call service...
✅ All services initialized
```

❌ **FAILURE - You might see:**
```
🚀 Initializing app services...
🔌 Connecting to Socket.IO...
❌ No auth token found, cannot connect to socket
❌ User must be logged in to connect to socket
```
**FIX:** User is not logged in properly. Check authentication.

OR:

```
🚀 Initializing app services...
🔌 Connecting to Socket.IO...
✅ Auth token found: eyJhbGciOiJIUzI1NiIs...
🔌 Socket server URL: https://tutor-app-backend-wtru.onrender.com
🔌 Attempting to connect to socket server...
🔌 Socket instance created, waiting for connection...
✅ Socket event handlers registered
❌❌❌ Socket connection error: [error details]
❌ Socket.IO connection failed or still connecting...
⚠️ Real-time features may not work!
```
**FIX:** Connection error - check error details.

### Step 5: Test Text Message

1. On Device 2 (student), go to chat with tutor
2. Send a text message: "Hello test"
3. Check if message appears on Device 1 (tutor) **immediately**

**Expected behavior:**
- Device 2 sends message
- Device 1 receives message **instantly** (no refresh needed)

### Step 6: Test Voice/Video Call

1. On Device 2 (student), initiate a video call to tutor
2. Check Device 1 (tutor) for incoming call screen

**Expected behavior:**
- Device 2 initiates call
- Device 1 shows incoming call screen **immediately**

### Step 7: Check Server Logs

Go to Render dashboard → `tutor-app-backend` → Logs

**Look for:**
```
🔌 User connected: [Name] ([userId])
💬 User [Name] joined chat [chatId]
📞 Incoming call event emitted to user_[userId]
```

## 🔍 WHAT TO SHARE

### If Socket Connection FAILS:

**Share these logs from mobile app:**
1. All messages starting with 🔌
2. All messages starting with ❌
3. Any error messages

**Share these logs from Render:**
1. Any "🔌 User connected" messages (or lack thereof)
2. Any authentication errors
3. Any Socket.IO errors

### If Socket Connection SUCCEEDS but Real-Time Doesn't Work:

**Share these logs from mobile app:**
1. The "✅✅✅ Socket connected successfully!" message
2. The Socket ID
3. Any messages when sending/receiving

**Share these logs from Render:**
1. The "🔌 User connected" messages
2. The "💬 Attempting to emit socket event..." messages
3. The "📞 Incoming call event emitted..." messages

## 🎯 EXPECTED OUTCOME

After rebuilding with enhanced logging, we will be able to see:

1. **Is the socket connecting?** (Look for ✅✅✅ message)
2. **If not, why?** (Look for ❌ error messages)
3. **Is the server receiving connections?** (Look for 🔌 in Render logs)
4. **Are events being emitted?** (Look for 💬 and 📞 in Render logs)
5. **Are events being received?** (Look for 💬 and 📞 in mobile logs)

## 🚨 COMMON ISSUES

### Issue 1: "No auth token found"
**Cause:** User not logged in or token not saved
**Fix:** Ensure user logs in successfully before testing

### Issue 2: "Socket connection error: Authentication error"
**Cause:** Token is invalid or expired
**Fix:** Logout and login again to get fresh token

### Issue 3: Socket connects but no events received
**Cause:** Not joining correct rooms or event names mismatch
**Fix:** Check event names match between client and server

### Issue 4: Socket connects on one device but not the other
**Cause:** Different app versions or network issues
**Fix:** Ensure both devices have same APK version

## 📞 NEXT STEPS

1. **Rebuild app** with new logging
2. **Install on both devices**
3. **Login on both devices**
4. **Check logs immediately** after login
5. **Test text message** between devices
6. **Share logs** (mobile + server) with results

---

**Remember:** The server is working perfectly. The issue is the mobile app not connecting to Socket.IO. These enhanced logs will tell us exactly why.
