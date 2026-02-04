# ❌ Agora Call Token Error - Missing Credentials

## Problem
When trying to make voice/video calls, you get:
```
❌ Agora error: ErrorCodeType.errInvalidToken
🔌 Connection state: ConnectionStateFailed, reason: ConnectionChangedInvalidToken
```

Also when ending the call:
```
❌ ERROR: 403 - Not authorized to end this call
```

## Root Cause
The Agora credentials in `server/.env` are **empty or placeholder values**:

```env
AGORA_APP_ID=
AGORA_APP_CERTIFICATE=your_certificate_here_after_enabling
```

Without valid Agora credentials, the server cannot generate valid tokens for voice/video calls.

## Solution

### Step 1: Get Agora Credentials

You need to get your Agora App ID and Certificate from the Agora Console:

1. Go to: https://console.agora.io/
2. Login or create an account (it's free)
3. Click "Project Management" in the left sidebar
4. Click "Create" to create a new project
5. Enter project name: "Tutor Booking App"
6. Choose "Secured mode: APP ID + Token"
7. Click "Submit"

### Step 2: Get App ID and Certificate

After creating the project:

1. You'll see your **App ID** - copy it
2. Click the "Edit" icon next to your project
3. Find "Primary Certificate" section
4. Click "Enable" if not enabled
5. Copy the **App Certificate**

### Step 3: Update server/.env File

Open `server/.env` and update these lines:

```env
# Replace with your actual Agora credentials
AGORA_APP_ID=your_actual_app_id_here
AGORA_APP_CERTIFICATE=your_actual_certificate_here
```

Example (with fake values):
```env
AGORA_APP_ID=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
AGORA_APP_CERTIFICATE=9876543210abcdefghijklmnopqrstuv
```

### Step 4: Restart the Server

**If running locally:**
```bash
cd server
# Ctrl+C to stop
npm start
```

**If on Render:**
```bash
# Update .env on Render dashboard
1. Go to https://dashboard.render.com
2. Click your service: tutor-app-backend-wtru
3. Click "Environment" tab
4. Add/Update:
   - AGORA_APP_ID = your_app_id
   - AGORA_APP_CERTIFICATE = your_certificate
5. Click "Save Changes"
6. Server will auto-restart
```

### Step 5: Test Calls Again

1. Open the mobile app
2. Go to any chat
3. Click the phone or video icon
4. Call should now connect successfully! ✅

## About the 403 Error

The "Not authorized to end this call" error happens because:
- The call fails to connect due to invalid token
- The call record is created but with wrong user IDs
- When trying to end, the authorization check fails

This will be fixed once you add valid Agora credentials.

## Agora Free Tier

Agora offers a generous free tier:
- **10,000 minutes/month** free
- Perfect for testing and small apps
- No credit card required for testing
- Upgrade only when you need more

## Important Notes

1. **Keep credentials secret**: Never commit `.env` file to GitHub
2. **Use test mode**: Agora has test mode for development
3. **Monitor usage**: Check Agora console for usage stats
4. **Token expiration**: Tokens expire after 1 hour (configurable)

## Files to Check

- `server/.env` - Add Agora credentials here
- `server/utils/agoraToken.js` - Token generation logic
- `server/controllers/callController.js` - Call initiation logic

## Testing Checklist

After adding credentials:
- [ ] Server restarts successfully
- [ ] No errors in server logs about Agora
- [ ] Voice call connects
- [ ] Video call connects
- [ ] Can hear audio
- [ ] Can see video (for video calls)
- [ ] Call ends properly
- [ ] Call history shows correct duration

The calls will work perfectly once you add your Agora credentials! 📞✅
