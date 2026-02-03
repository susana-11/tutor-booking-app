# Local Network Testing Guide - Two Physical Devices

## ✅ Configuration Complete

Your app is now configured to work with two physical devices on your local network.

## 📱 Setup Steps

### 1. Server Setup (Already Running)
Your server is running on: `http://192.168.1.5:5000`

**Important:** Make sure your server is running:
```bash
cd server
npm start
```

### 2. Mobile App Configuration (Already Updated)
The app is now configured to use: `http://192.168.1.5:5000/api`

### 3. Network Requirements
- ✅ Both phones must be connected to the **same WiFi network** as your computer
- ✅ Your computer's firewall must allow incoming connections on port 5000
- ✅ Your WiFi router must allow device-to-device communication (most home routers do)

### 4. Firewall Configuration (Windows)

Run this command to allow Node.js through Windows Firewall:
```cmd
netsh advfirewall firewall add rule name="Node.js Server" dir=in action=allow protocol=TCP localport=5000
```

Or manually:
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. Enter port 5000 → Next
6. Allow the connection → Next
7. Apply to all profiles → Next
8. Name it "Tutor App Server" → Finish

### 5. Build and Install on Both Phones

**For Android:**
```bash
cd mobile_app
flutter build apk --release
```

The APK will be at: `mobile_app/build/app/outputs/flutter-apk/app-release.apk`

Transfer this APK to both phones and install it.

**Or use debug mode (faster for testing):**
```bash
# Connect phone 1 via USB
flutter run

# Then connect phone 2 and run on it
flutter run -d <device-id>
```

### 6. Test Accounts

**Student Account:**
- Email: etsebruk amanuel's email
- Phone: Student's phone number

**Tutor Account:**
- Email: bubuam13@gmail.com
- Phone: 0923394163
- Subject: Economics

### 7. Testing Flow

1. **Phone 1 (Student):**
   - Login as student
   - Search for tutors
   - Find "hindekie amanuel" (Economics tutor)
   - Book a session
   - Make payment via Chapa
   - Wait for tutor to accept

2. **Phone 2 (Tutor):**
   - Login as tutor
   - Go to Bookings
   - Accept the booking request

3. **Both Phones:**
   - When session time arrives, both can start the session
   - Video call will connect via Agora
   - Test chat, video, audio
   - End session
   - Rate each other

### 8. Troubleshooting

**If phones can't connect to server:**

1. Check your computer's IP hasn't changed:
   ```cmd
   ipconfig | findstr /i "IPv4"
   ```

2. Test server accessibility from phone browser:
   - Open browser on phone
   - Go to: `http://192.168.1.5:5000`
   - You should see a response

3. Check firewall is allowing connections

4. Verify both phones are on same WiFi as computer

**If you need to switch back to emulator:**
Change `app_config.dart` back to:
```dart
static const String _baseUrlDev = 'http://10.0.2.2:5000/api';
```

## 🚀 Quick Start Commands

```bash
# Terminal 1: Start server
cd server
npm start

# Terminal 2: Build app for phone 1
cd mobile_app
flutter run

# Terminal 3: Build app for phone 2 (if connected)
cd mobile_app
flutter run -d <device-id>
```

## 📊 What to Test

- ✅ Login on both devices
- ✅ Tutor profile creation
- ✅ Student search for tutors
- ✅ Booking creation
- ✅ Payment flow (Chapa)
- ✅ Tutor accepting booking
- ✅ Session start (both sides)
- ✅ Video call (Agora)
- ✅ Chat during session
- ✅ Session end
- ✅ Rating/review system
- ✅ Notifications

## 🌐 Alternative: Cloud Deployment

If local network testing doesn't work or you want permanent access, see `CLOUD_DEPLOYMENT_GUIDE.md` for deploying to Render.com (free tier).
