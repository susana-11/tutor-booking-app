# 🔨 Rebuild App for Review System

## Quick Rebuild Commands

### Option 1: Clean Rebuild (Recommended)
```bash
cd mobile_app
flutter clean
flutter pub get
flutter run
```

### Option 2: Release Build
```bash
cd mobile_app
flutter clean
flutter pub get
flutter build apk --release
```

### Option 3: Debug Build
```bash
cd mobile_app
flutter run --debug
```

---

## What to Test After Rebuild

### 1. Complete a Session
- Start session between student and tutor
- Both join successfully
- End session from either side

### 2. Rate the Session
- Click "Rate Now" in completion dialog
- ✅ Should open review screen (not return to bookings)
- See tutor name and subject
- Rate with stars
- Write review
- Submit successfully

### 3. Check Tutor Profile
- Go to tutor search
- Find and open tutor profile
- Scroll to Reviews section
- ✅ Should see rating summary
- ✅ Should see rating distribution
- ✅ Should see recent reviews
- Click "See All" to view all reviews

### 4. Verify Notifications
- Switch to tutor account
- Check notifications
- ✅ Should see "New Review Received ⭐"

---

## Expected Results

✅ "Rate Now" opens review screen
✅ Review screen shows tutor details
✅ Can submit review successfully
✅ Review appears on tutor profile
✅ Average rating updates
✅ Rating distribution displays
✅ Recent reviews show
✅ Tutor receives notification

---

## If Issues Occur

### Issue: Still returns to bookings
```bash
# Try harder clean
cd mobile_app
flutter clean
rm -rf build/
rm -rf .dart_tool/
flutter pub get
flutter run
```

### Issue: Reviews not showing
```bash
# Check backend is running
cd server
npm start

# Check API endpoint
curl http://localhost:5000/api/reviews/tutor/TUTOR_ID
```

### Issue: Build errors
```bash
# Update dependencies
cd mobile_app
flutter pub upgrade
flutter pub get
flutter run
```

---

## Files Changed (For Reference)

1. `mobile_app/lib/features/session/screens/active_session_screen.dart`
2. `mobile_app/lib/features/student/screens/create_review_screen.dart`
3. `mobile_app/lib/features/student/screens/tutor_detail_screen.dart`

---

## Ready to Test!

After rebuild, the review system should work perfectly like Uber/Airbnb! 🚀
