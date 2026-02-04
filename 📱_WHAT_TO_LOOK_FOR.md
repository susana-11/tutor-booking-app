# 📱 What to Look For After Rebuild

## 🎯 QUICK REFERENCE

After rebuilding and installing the app, here's what to check:

---

## 1️⃣ IMMEDIATELY AFTER LOGIN

### ✅ SUCCESS - You Should See:
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

**This means:** Socket.IO is connected! Real-time features should work!

---

### ❌ FAILURE - You Might See:

#### Scenario A: No Auth Token
```
🚀 Initializing app services...
🔌 Connecting to Socket.IO...
❌ No auth token found, cannot connect to socket
❌ User must be logged in to connect to socket
```

**This means:** User is not logged in properly
**Fix:** Logout and login again

---

#### Scenario B: Connection Error
```
🚀 Initializing app services...
🔌 Connecting to Socket.IO...
✅ Auth token found: eyJhbGciOiJIUzI1NiIs...
🔌 Socket server URL: https://tutor-app-backend-wtru.onrender.com
🔌 Attempting to connect to socket server...
🔌 Socket instance created, waiting for connection...
✅ Socket event handlers registered
❌❌❌ Socket connection error: [error details here]
❌ Error type: [type]
❌ Error details: [details]
❌ Socket.IO connection failed or still connecting...
⚠️ Real-time features may not work!
```

**This means:** Socket connection failed
**Fix:** Share the error details - we'll fix based on the error

---

#### Scenario C: Timeout (No Success or Error)
```
🚀 Initializing app services...
🔌 Connecting to Socket.IO...
✅ Auth token found: eyJhbGciOiJIUzI1NiIs...
🔌 Socket server URL: https://tutor-app-backend-wtru.onrender.com
🔌 Attempting to connect to socket server...
🔌 Socket instance created, waiting for connection...
✅ Socket event handlers registered
❌ Socket.IO connection failed or still connecting...
⚠️ Real-time features may not work!
```

**This means:** Connection is timing out
**Fix:** Could be network issue or server not responding

---

## 2️⃣ WHEN SENDING TEXT MESSAGE

### ✅ SUCCESS - You Should See:
```
💬 Message sent to chat: [chatId]
```

**On receiving device:**
```
💬 New message received: [message data]
```

**This means:** Messages are working in real-time!

---

### ❌ FAILURE - You Might See:
```
ℹ️ Socket not connected, send_message will be sent via HTTP
```

**This means:** Socket not connected, using HTTP fallback
**Result:** Message will be saved but not delivered in real-time

---

## 3️⃣ WHEN MAKING VOICE/VIDEO CALL

### ✅ SUCCESS - You Should See:

**On calling device:**
```
📞 Initiating video call to [receiverId]
✅ Call initiated: [callId]
```

**On receiving device:**
```
📞📞📞 Incoming call received via socket: [call data]
```

**This means:** Calls are working in real-time!

---

### ❌ FAILURE - You Might See:

**On calling device:**
```
📞 Initiating video call to [receiverId]
✅ Call initiated: [callId]
```

**On receiving device:**
```
(No message - call doesn't ring)
```

**This means:** Socket not connected, call notification not received

---

## 4️⃣ CONTACT SHARING

### ✅ SUCCESS - You Should See:
1. Tap attachment icon
2. Select "Contact"
3. Permission dialog appears (first time only)
4. Grant permission
5. Contact picker opens
6. Select contact
7. Contact appears in chat

---

### ❌ FAILURE - You Might See:
1. Tap attachment icon
2. Select "Contact"
3. "Permission required" message
4. Nothing happens

**Fix:** Uninstall app completely and reinstall

---

## 📋 WHAT TO SHARE

### If Socket Connection FAILS:

**Copy and share ALL messages containing:**
- 🔌 (socket connection)
- ❌ (errors)
- ⚠️ (warnings)

**Also share from Render server logs:**
- Any "🔌 User connected" messages (or lack thereof)
- Any Socket.IO errors

---

### If Socket Connection SUCCEEDS but Real-Time Doesn't Work:

**Copy and share:**
- The "✅✅✅ Socket connected successfully!" message
- The Socket ID
- Messages when sending/receiving (💬 and 📞)

**Also share from Render server logs:**
- "🔌 User connected" messages
- "💬 Attempting to emit socket event" messages
- "📞 Incoming call event emitted" messages

---

## 🎯 QUICK TEST CHECKLIST

After rebuild and login:

- [ ] Check logs for "✅✅✅ Socket connected successfully!"
- [ ] If connected: Test text message (should appear instantly)
- [ ] If connected: Test voice/video call (should ring instantly)
- [ ] Test contact sharing (should work after permission)
- [ ] If anything fails: Copy logs and share

---

## 🚨 REMEMBER

**The enhanced logging will show us EXACTLY what's happening!**

- If socket connects → We'll see ✅✅✅
- If socket fails → We'll see ❌ with error details
- If events are sent → We'll see 💬 and 📞
- If events are received → We'll see 💬 and 📞

**Just rebuild, test, and share the logs!**
