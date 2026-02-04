# 🔍 AGORA CONNECTION ISSUE - DEBUGGING

## 🐛 PROBLEM

Both devices show "Waiting for other participant..." - they can't see each other.

**This means:**
- ❌ Devices are NOT joining the same Agora channel
- ❌ OR they're using incompatible tokens
- ❌ OR Agora App ID is wrong
- ❌ OR Network/firewall blocking Agora

## ✅ WHAT WORKS

- ✅ Camera flip works (local camera is working)
- ✅ Permissions granted
- ✅ App initializes without errors

## 🔍 ROOT CAUSES TO CHECK

### 1. Different Channel Names
**Problem:** Student and tutor joining different channels
**Check:** Are they using the same booking/session?

### 2. Token Issues
**Problem:** Tokens expired or invalid
**Check:** Server generating valid Agora tokens?

### 3. Agora App ID Mismatch
**Problem:** Mobile app using different App ID than server
**Check:** 
- Mobile: `app_config.dart`
- Server: `.env` file

### 4. Network/Firewall
**Problem:** Agora servers blocked
**Check:** Internet connection, firewall settings

## 🔧 DEBUGGING STEPS

### Step 1: Check Console Logs

**On Student Device:**
```
Look for:
🎥 Initializing Agora...
📺 Channel: session_xxx, UID: 1
✅ Agora initialized
✅ Event handlers registered
✅ Joined channel
✅ Speakerphone enabled
```

**On Tutor Device:**
```
Look for:
🎥 Initializing Agora...
📺 Channel: session_xxx, UID: 2
✅ Agora initialized
✅ Event handlers registered
✅ Joined channel
✅ Speakerphone enabled
```

**CRITICAL:** Channel name must be EXACTLY the same!

### Step 2: Check Server Logs

When session starts, server should log:
```
📱 Student starting session
🎥 Generating Agora token
   Channel: session_67890abcdef
   UID: 1
   Token: 006abc...

📱 Tutor joining session
🎥 Generating Agora token
   Channel: session_67890abcdef  ← MUST BE SAME!
   UID: 2
   Token: 006def...
```

### Step 3: Verify Agora Credentials

**Check Mobile App:**
```dart
// mobile_app/lib/core/config/app_config.dart
static const String agoraAppId = '0ad4c02139aa48b28e813b4e9676ea0a';
```

**Check Server:**
```bash
# server/.env
AGORA_APP_ID=0ad4c02139aa48b28e813b4e9676ea0a
AGORA_APP_CERTIFICATE=your_certificate_here
```

**MUST MATCH!**

## 🛠️ QUICK FIXES TO TRY

### Fix 1: Check Same Booking
```
1. Student starts session on Booking #123
2. Tutor MUST join session on Booking #123
3. NOT a different booking!
```

### Fix 2: Restart Both Apps
```
1. Close both apps completely
2. Reopen both apps
3. Try again
```

### Fix 3: Check Server Running
```bash
cd server
npm start

# Should see:
Server running on port 5000
MongoDB connected
```

### Fix 4: Verify Agora App ID
```bash
# Check server .env
cat server/.env | grep AGORA

# Check mobile app
cat mobile_app/lib/core/config/app_config.dart | grep agora
```

## 📱 TESTING PROCEDURE

### Correct Flow:

**Device 1 (Student):**
1. Login as student
2. Go to Bookings
3. Find booking (e.g., "Economics - Jan 15, 2:00 PM")
4. Click "Start Session"
5. **WAIT** - Don't close app
6. Note the booking ID in console

**Device 2 (Tutor):**
1. Login as tutor
2. Go to Bookings
3. Find **SAME** booking ("Economics - Jan 15, 2:00 PM")
4. Click "Join Session"
5. Should see student's video

### Common Mistakes:

❌ **Wrong:** Student starts Booking A, Tutor joins Booking B
✅ **Right:** Both join the SAME booking

❌ **Wrong:** Start session before scheduled time
✅ **Right:** Start within 15 minutes of scheduled time

❌ **Wrong:** Different Agora App IDs
✅ **Right:** Same App ID in mobile and server

## 🔍 DIAGNOSTIC COMMANDS

### Check if server is generating tokens:
```bash
cd server
node scripts/testAgora.js
```

### Check booking status:
```bash
cd server
node scripts/checkBooking.js
```

### Check Agora credentials:
```bash
# Windows
type server\.env | findstr AGORA

# Check mobile
type mobile_app\lib\core\config\app_config.dart | findstr agora
```

## 🎯 MOST LIKELY CAUSES

### 1. Token Generation Issue (80% probability)
**Symptom:** Both join but can't see each other
**Fix:** Check server is generating valid tokens
**Test:** Look at server console when starting session

### 2. Different Channels (15% probability)
**Symptom:** Both waiting forever
**Fix:** Ensure both joining same booking
**Test:** Check channel names in console logs

### 3. Agora App ID Mismatch (5% probability)
**Symptom:** Connection fails immediately
**Fix:** Verify App IDs match
**Test:** Compare .env and app_config.dart

## 📝 WHAT TO CHECK NOW

1. **Are both devices using the SAME booking?**
   - Check booking ID
   - Check session time
   - Check tutor/student names

2. **Is server running and generating tokens?**
   - Check server console
   - Look for token generation logs
   - Verify no errors

3. **Do Agora credentials match?**
   - Mobile app: `0ad4c02139aa48b28e813b4e9676ea0a`
   - Server .env: Should be same

4. **Are console logs showing channel names?**
   - Student: `Channel: session_xxx`
   - Tutor: `Channel: session_xxx` (must be same!)

## 🚀 NEXT STEPS

1. **Check server console** - Is it generating tokens?
2. **Check mobile console** - What channel names?
3. **Verify same booking** - Both joining same session?
4. **Check Agora App ID** - Does it match?

---

**NO, YOU DON'T NEED TO PUSH TO GIT/RENDER!**

The mobile app changes are local only. The issue is with:
- Agora channel connection
- Token generation
- Or same booking verification

Let's debug this step by step! 🔍
