# ✅ Two Device Testing - Ready to Go!

## 🎯 Current Status

Your app is **configured and ready** for testing with two physical devices on your local network.

## 📱 What's Been Done

✅ **Mobile app configured** to use your local IP: `192.168.1.5:5000`
✅ **Firewall rule exists** - Port 5000 is open for incoming connections
✅ **Server is running** on MongoDB Atlas (cloud database)
✅ **All features implemented:**
   - Authentication
   - Tutor profiles
   - Booking system
   - Payment (Chapa)
   - Video calls (Agora)
   - Chat
   - Notifications
   - Rating/Review system

## 🚀 Quick Start (3 Steps)

### Step 1: Start Server (If Not Running)
```bash
cd server
npm start
```

You should see:
```
🚀 Server running on port 5000
✅ MongoDB Connected
```

### Step 2: Build & Install on Both Phones

**Option A: Release Build (Recommended)**
```bash
cd mobile_app
flutter build apk --release
```

Then:
1. Find APK at: `mobile_app\build\app\outputs\flutter-apk\app-release.apk`
2. Transfer to both phones (USB, email, or cloud storage)
3. Install on both phones

**Option B: Debug Build (Faster)**
```bash
# Connect Phone 1 via USB
cd mobile_app
flutter run

# Connect Phone 2 via USB (in another terminal)
flutter devices  # Get device ID
flutter run -d <device-id>
```

### Step 3: Test!

**Phone 1 (Student):**
1. Login as student (etsebruk amanuel)
2. Search for tutors
3. Find "hindekie amanuel" (Economics)
4. Book a session for today
5. Pay via Chapa
6. Wait for tutor to accept

**Phone 2 (Tutor):**
1. Login as tutor (bubuam13@gmail.com / 0923394163)
2. Go to Bookings tab
3. Accept the booking
4. When time comes, tap "Start Session"

**Both Phones:**
- Video call connects
- Test chat
- End session
- Rate each other

## ⚠️ Important Checks

### Before Testing:

1. **Both phones on same WiFi as computer** ✓
   - Check WiFi name on both phones
   - Should match your computer's WiFi

2. **Server is running** ✓
   ```bash
   cd server
   npm start
   ```

3. **Test server from phone browser** ✓
   - Open browser on phone
   - Go to: `http://192.168.1.5:5000`
   - Should see: "Cannot GET /" (this is normal - means server is reachable)

### If Connection Fails:

1. **Check your IP hasn't changed:**
   ```cmd
   ipconfig | findstr /i "IPv4"
   ```
   If different from `192.168.1.5`, update `mobile_app/lib/core/config/app_config.dart`

2. **Restart server:**
   ```bash
   cd server
   npm start
   ```

3. **Rebuild app:**
   ```bash
   cd mobile_app
   flutter build apk --release
   ```

## 📊 Test Checklist

Use this to track your testing:

- [ ] Student login works
- [ ] Tutor login works
- [ ] Search for tutors shows results
- [ ] Can view tutor profile
- [ ] Can see available time slots
- [ ] Can create booking
- [ ] Payment redirect works (Chapa)
- [ ] Payment verification works
- [ ] Tutor receives booking notification
- [ ] Tutor can accept booking
- [ ] Student sees booking confirmed
- [ ] Both can start session at scheduled time
- [ ] Video call connects (Agora)
- [ ] Audio works both ways
- [ ] Video works both ways
- [ ] Chat works during session
- [ ] Can end session
- [ ] Rating screen appears
- [ ] Can submit rating
- [ ] Rating appears on tutor profile

## 🌐 Alternative: Cloud Deployment

If local network testing doesn't work or you want to test from different locations:

**See:** `CLOUD_DEPLOYMENT_GUIDE.md`

This will deploy your server to Render.com (free tier) so you can access it from anywhere.

## 🔧 Troubleshooting

### "Cannot connect to server"

1. Check server is running: `cd server && npm start`
2. Check IP address: `ipconfig | findstr /i "IPv4"`
3. Test from phone browser: `http://192.168.1.5:5000`
4. Check both phones on same WiFi
5. Check Windows Firewall allows port 5000

### "No available slots"

1. Make sure tutor has created availability
2. Slots must be in the future (not past)
3. Check tutor's schedule screen

### "Payment failed"

1. Check Chapa test credentials in `.env`
2. Use test card numbers from Chapa docs
3. Check server logs for errors

### "Video call not connecting"

1. Check Agora App ID in `.env` and `app_config.dart`
2. Make sure both phones have camera/mic permissions
3. Check internet connection on both phones

### "Authorization error"

1. Make sure you're logged in
2. Check token hasn't expired (login again)
3. Check server logs for details

## 📞 Support

If you encounter issues:
1. Check server terminal for error logs
2. Check phone logs: `flutter logs` (if connected via USB)
3. Review the error message carefully
4. Check the relevant guide:
   - `LOCAL_NETWORK_TESTING_GUIDE.md` - Local setup
   - `CLOUD_DEPLOYMENT_GUIDE.md` - Cloud deployment
   - `QUICK_TEST_GUIDE.md` - Feature testing

## 🎉 You're Ready!

Everything is configured. Just:
1. Start server
2. Build app
3. Install on both phones
4. Test!

Good luck with your testing! 🚀
