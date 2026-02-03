# 🚀 Start Testing NOW - Quick Guide

## ⚡ 3-Minute Setup

Your app is **100% ready** for two-device testing. Here's the fastest way to start:

---

## Step 1: Start Server (30 seconds)

**Option A:** Double-click `start-server.bat`

**Option B:** Run manually:
```bash
cd server
npm start
```

✅ Wait for: `🚀 Server running on port 5000`

---

## Step 2: Build App (2 minutes)

```bash
cd mobile_app
flutter build apk --release
```

✅ Wait for: `Built build\app\outputs\flutter-apk\app-release.apk`

---

## Step 3: Install on Both Phones (1 minute)

1. Find APK: `mobile_app\build\app\outputs\flutter-apk\app-release.apk`
2. Transfer to both phones (USB cable, email, or Google Drive)
3. Install on both phones
4. **Important:** Make sure both phones are on the **same WiFi** as your computer

---

## Step 4: Test! (5 minutes)

### Phone 1 - Student:
1. Open app
2. Login with student account
3. Tap "Search Tutors"
4. Find "hindekie amanuel"
5. Tap to view profile
6. Tap "Book Session"
7. Select today's date
8. Choose available time slot
9. Tap "Book Now"
10. Complete payment (use Chapa test card)

### Phone 2 - Tutor:
1. Open app
2. Login with tutor account (bubuam13@gmail.com)
3. Tap "Bookings" tab
4. See new booking request
5. Tap "Accept"

### Both Phones - Session:
1. Wait for scheduled time (or book for "now")
2. Both phones: Tap "Start Session"
3. Video call connects!
4. Test video, audio, chat
5. Tap "End Session"
6. Rate each other

---

## ✅ Verification Checklist

Before testing, verify:

- [ ] Server running: `http://192.168.1.5:5000`
- [ ] Both phones on same WiFi as computer
- [ ] App installed on both phones
- [ ] Test accounts ready:
  - Student: etsebruk amanuel
  - Tutor: bubuam13@gmail.com / 0923394163

---

## 🔧 Quick Troubleshooting

### "Cannot connect to server"
1. Check server is running
2. Test in phone browser: `http://192.168.1.5:5000`
3. Check WiFi connection

### "No available slots"
1. Login as tutor
2. Go to Schedule
3. Add availability for today

### "Payment not working"
- Use Chapa test mode (already configured)
- Any test card number works in test mode

---

## 📱 Test Accounts

**Student:**
- Name: etsebruk amanuel
- Use the registered email/phone

**Tutor:**
- Email: bubuam13@gmail.com
- Phone: 0923394163
- Password: (your password)
- Subject: Economics

---

## 🎯 What to Test

### Core Flow:
1. ✅ Login (both)
2. ✅ Search tutors (student)
3. ✅ View profile (student)
4. ✅ Book session (student)
5. ✅ Pay (student)
6. ✅ Accept booking (tutor)
7. ✅ Start session (both)
8. ✅ Video call (both)
9. ✅ End session (both)
10. ✅ Rate (both)

### Additional Features:
- Chat during session
- View booking history
- View earnings (tutor)
- View reviews
- Edit profile
- Manage schedule (tutor)

---

## 📚 More Information

- **Detailed local setup:** `LOCAL_NETWORK_TESTING_GUIDE.md`
- **Cloud deployment:** `CLOUD_DEPLOYMENT_GUIDE.md`
- **All options:** `TESTING_OPTIONS_SUMMARY.md`
- **Complete guide:** `TWO_DEVICE_TESTING_READY.md`

---

## 🎉 Ready to Go!

Everything is configured. Just:
1. Start server → 2. Build app → 3. Install → 4. Test!

**Total time: ~5 minutes**

Good luck! 🚀
