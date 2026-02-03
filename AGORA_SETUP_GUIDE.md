# Agora Account Setup Guide

## Step 1: Create Agora Account

1. **Go to Agora Console**
   - Visit: https://console.agora.io/
   - Click "Sign Up" (top right)

2. **Sign Up Options**
   - Use Email
   - Or sign up with Google/GitHub
   - Fill in your details:
     - Email address
     - Password
     - Company name (can use "Personal" or your app name)
     - Country/Region

3. **Verify Email**
   - Check your email inbox
   - Click the verification link
   - Complete email verification

## Step 2: Create a Project

1. **Access Console**
   - Log in to https://console.agora.io/
   - You'll see the dashboard

2. **Create New Project**
   - Click "Project Management" in left sidebar
   - Click "Create" button
   - Fill in project details:
     - **Project Name**: "Tutor Booking App" (or your preferred name)
     - **Use Case**: Select "Social" or "Education"
     - **Authentication Mechanism**: Select "Secured mode: APP ID + Token"
       - ⚠️ IMPORTANT: Choose "Secured mode" for production security

3. **Submit**
   - Click "Submit" to create the project

## Step 3: Get Your Credentials

After creating the project, you'll see:

### App ID
- This is displayed immediately after project creation
- Format: 32-character hexadecimal string
- Example: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`
- **Copy this** - you'll need it

### App Certificate
1. Click on your project name
2. Find "Primary Certificate" section
3. Click "Enable" button
4. A certificate will be generated
5. Format: 32-character hexadecimal string
6. **Copy this** - you'll need it
7. ⚠️ **IMPORTANT**: Save it securely, you can't view it again!

## Step 4: Configure Project Settings

1. **Enable Features**
   - In project settings, enable:
     - ✅ RTC (Real-Time Communication) - Already enabled by default
     - ✅ Cloud Recording (Optional - for recording calls)
     - ✅ Real-time Messaging (Optional - for chat features)

2. **Set Usage Limits** (Optional)
   - You can set monthly usage limits to control costs
   - Free tier includes:
     - 10,000 minutes/month free
     - After that: ~$0.99 per 1,000 minutes

## Step 5: Add Credentials to Your Project

Once you have your App ID and Certificate:

### 5.1 Update Server Environment Variables

Add to `server/.env`:
```env
# Agora Configuration
AGORA_APP_ID=your_app_id_here
AGORA_APP_CERTIFICATE=your_certificate_here
```

### 5.2 Update Mobile App Configuration

Update `mobile_app/lib/core/config/app_config.dart`:
```dart
// Agora Configuration
static const String agoraAppId = 'your_app_id_here';
```

⚠️ **Security Note**: 
- Never commit the App Certificate to version control
- Keep it in `.env` file only
- The App ID can be in the mobile app (it's public)
- The Certificate should ONLY be on the server

## Step 6: Install Required Packages

### Server-Side
```bash
cd server
npm install agora-access-token
```

This package is needed to generate RTC tokens on the server.

### Mobile App
Already installed in your `pubspec.yaml`:
```yaml
agora_rtc_engine: ^6.3.0
```

## Step 7: Test Your Setup

### Quick Test Checklist
- [ ] Agora account created
- [ ] Project created with "Secured mode"
- [ ] App ID copied
- [ ] App Certificate copied and saved
- [ ] Credentials added to `.env` file
- [ ] `agora-access-token` package installed on server
- [ ] Mobile app has `agora_rtc_engine` package

## Step 8: Verify Credentials

Create a test script to verify your credentials work:

```javascript
// server/scripts/testAgora.js
require('dotenv').config();
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

const appId = process.env.AGORA_APP_ID;
const appCertificate = process.env.AGORA_APP_CERTIFICATE;

if (!appId || !appCertificate) {
  console.error('❌ Missing Agora credentials in .env file');
  process.exit(1);
}

console.log('✅ App ID found:', appId.substring(0, 8) + '...');
console.log('✅ App Certificate found:', appCertificate.substring(0, 8) + '...');

// Test token generation
const channelName = 'test-channel';
const uid = 12345;
const role = RtcRole.PUBLISHER;
const expirationTimeInSeconds = 3600;
const currentTimestamp = Math.floor(Date.now() / 1000);
const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

try {
  const token = RtcTokenBuilder.buildTokenWithUid(
    appId,
    appCertificate,
    channelName,
    uid,
    role,
    privilegeExpiredTs
  );
  
  console.log('✅ Token generated successfully!');
  console.log('Token:', token.substring(0, 20) + '...');
  console.log('\n🎉 Agora setup is complete and working!');
} catch (error) {
  console.error('❌ Error generating token:', error.message);
  process.exit(1);
}
```

Run the test:
```bash
node server/scripts/testAgora.js
```

## Troubleshooting

### Issue: "Invalid App ID"
- **Solution**: Double-check you copied the entire App ID (32 characters)
- Make sure there are no extra spaces

### Issue: "Invalid Certificate"
- **Solution**: Regenerate the certificate in Agora Console
- Copy it immediately (you can't view it again)

### Issue: "Token generation failed"
- **Solution**: Ensure you selected "Secured mode" when creating the project
- Verify the certificate is enabled

### Issue: "Package not found"
- **Solution**: Run `npm install agora-access-token` in server directory

## Free Tier Limits

Agora offers generous free tier:
- **10,000 minutes/month** free
- Includes both voice and video
- Resets monthly
- Perfect for development and testing

### Pricing After Free Tier
- Voice: ~$0.99 per 1,000 minutes
- HD Video: ~$3.99 per 1,000 minutes
- Recording: Additional charges apply

## Security Best Practices

1. **Never expose App Certificate**
   - Keep it server-side only
   - Don't commit to Git
   - Use environment variables

2. **Use Token Authentication**
   - Always use "Secured mode"
   - Generate tokens on server
   - Set appropriate expiration times

3. **Implement Access Control**
   - Verify user permissions before generating tokens
   - Only allow tutor-student pairs to call each other
   - Log all call attempts

4. **Monitor Usage**
   - Check Agora Console regularly
   - Set up usage alerts
   - Monitor for unusual activity

## Next Steps

Once your Agora account is set up:

1. ✅ Verify credentials with test script
2. 📝 Implement token generation on server
3. 📱 Build call screens in mobile app
4. 🧪 Test voice calls
5. 📹 Test video calls
6. 🚀 Deploy to production

## Support Resources

- **Documentation**: https://docs.agora.io/
- **API Reference**: https://api-ref.agora.io/
- **Community**: https://www.agora.io/en/community/
- **Support**: support@agora.io

---

## Quick Reference

After setup, you'll have:
- **App ID**: Public identifier (can be in mobile app)
- **App Certificate**: Secret key (server-side only)
- **Token**: Generated dynamically for each call (expires after 1 hour)

**Ready to proceed?** Once you have your credentials, let me know and I'll help you implement the calling features!
