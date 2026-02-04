# 🧪 Review System - Quick Test Guide

## Prerequisites
- Two devices (or emulator + physical device)
- One student account
- One tutor account
- Completed session between them

---

## Test Steps

### 1. Complete a Session
```
1. Start session as student
2. Join session as tutor
3. Both see video/audio
4. Click "End Session" (either side)
5. Confirm end session
```

### 2. Rate the Session
```
1. See "Session Complete!" dialog
2. Click "Rate Now" button
3. Review screen should open
4. See tutor name and subject
5. Tap stars to rate (1-5)
6. Write review text (optional)
7. Click "Submit Review"
8. See success message
```

### 3. Check Tutor Profile
```
1. Go to tutor search
2. Find the tutor
3. Open tutor profile
4. Scroll to "Reviews" section
5. Should see:
   - Average rating updated
   - Your review displayed
   - Rating distribution
   - Time ago (e.g., "Just now")
```

### 4. Check Notifications
```
1. Switch to tutor account
2. Open notifications
3. Should see "New Review Received ⭐"
4. Shows student name and rating
```

---

## Expected Results

✅ Navigation works (no return to bookings)
✅ Review screen shows tutor details
✅ Can submit review successfully
✅ Review appears on tutor profile
✅ Average rating updates
✅ Tutor receives notification
✅ Professional UI/UX

---

## Common Issues

### Issue: Returns to bookings
**Fix**: Rebuild app after code changes

### Issue: Review not showing
**Fix**: Refresh tutor profile or check backend logs

### Issue: Rating not updating
**Fix**: Check TutorProfile.updateAverageRating() method

---

## Quick Commands

```bash
# Rebuild app
cd mobile_app
flutter clean
flutter pub get
flutter run

# Check backend logs
cd server
npm start
```

---

**Test complete when all ✅ are working!**
