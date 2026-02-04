# 🔨 REBUILD APP FOR VIDEO UI

## ✅ CHANGES MADE

The session screen now has **FULL VIDEO/VOICE UI** with:
- ✅ Video display (remote + local)
- ✅ Audio/video controls
- ✅ Professional dark theme
- ✅ Session notes dialog

---

## 🚀 REBUILD STEPS

### 1. Clean Build
```bash
cd mobile_app
flutter clean
```

### 2. Get Dependencies
```bash
flutter pub get
```

### 3. Build APK
```bash
flutter build apk --release
```

### 4. Install on Device
```bash
flutter install
```

**OR** manually install:
```
APK Location: mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

---

## 📱 TESTING CHECKLIST

### Before Testing:
- [ ] 2 devices ready (or 1 device + 1 emulator)
- [ ] Both devices connected to internet
- [ ] Camera/microphone permissions will be requested
- [ ] Agora credentials configured

### Test Steps:

#### 1. Start Session (Device 1 - Student)
- [ ] Login as student
- [ ] Go to Bookings
- [ ] Find active booking
- [ ] Click "Start Session"
- [ ] Grant camera/mic permissions
- [ ] See your video in corner
- [ ] See "Waiting for other participant..."

#### 2. Join Session (Device 2 - Tutor)
- [ ] Login as tutor
- [ ] Go to Bookings
- [ ] Find same booking
- [ ] Click "Join Session"
- [ ] Grant camera/mic permissions
- [ ] See student's video full screen
- [ ] See your video in corner

#### 3. Test Controls (Both Devices)
- [ ] Click Mute - audio stops
- [ ] Click Unmute - audio resumes
- [ ] Click Camera Off - video stops
- [ ] Click Camera On - video resumes
- [ ] Click Flip - camera switches
- [ ] Click Speaker - audio output changes

#### 4. Test Video Display
- [ ] Remote video shows full screen
- [ ] Local video shows in corner
- [ ] Timer counts down
- [ ] UI is responsive

#### 5. End Session (Either Device)
- [ ] Click "End Session"
- [ ] Dialog appears
- [ ] Add optional notes
- [ ] Click "End Session" in dialog
- [ ] Session ends on both devices
- [ ] Rating prompt appears

---

## 🎯 WHAT TO LOOK FOR

### ✅ GOOD SIGNS:
- Video appears immediately
- Audio is clear
- Controls respond instantly
- No lag or freezing
- Timer updates smoothly
- Professional dark UI

### ❌ PROBLEMS TO WATCH FOR:
- Black screen (no video)
- No audio
- Controls not working
- App crashes
- Permissions denied

---

## 🔧 IF ISSUES OCCUR

### No Video Showing:
```bash
# Check Agora credentials
cat mobile_app/lib/core/config/app_config.dart | grep AGORA
cat server/.env | grep AGORA
```

### Permissions Denied:
```bash
# Reinstall app to reset permissions
flutter clean
flutter install
```

### Build Errors:
```bash
# Full clean rebuild
cd mobile_app
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter build apk
```

### Connection Issues:
```bash
# Check server is running
cd server
npm start

# Check mobile app can reach server
# Update API_BASE_URL in app_config.dart
```

---

## 📊 EXPECTED BEHAVIOR

### Session Start:
```
1. Click "Start Session"
2. Permissions requested (camera + mic)
3. Video initializes (2-3 seconds)
4. Local preview appears in corner
5. "Waiting..." message shows
6. Other person joins
7. Their video appears full screen
8. Session begins!
```

### During Session:
```
- Both see each other's video
- Both hear each other's audio
- Timer counts down
- Controls work instantly
- UI is smooth and responsive
```

### Session End:
```
1. Click "End Session"
2. Dialog appears
3. Add notes (optional)
4. Confirm
5. Video stops
6. Both return to bookings
7. Rating prompt shows
```

---

## 🎥 UI COMPONENTS

### What You Should See:

**Top Bar:**
- Back button (←)
- Other person's name
- Timer (MM:SS remaining)

**Video Area:**
- Remote video (full screen)
- Local video (small corner)
- OR "Waiting..." message

**Bottom Bar:**
- 4 control buttons
- End Session button (red)

**Colors:**
- Background: Black
- Overlays: Semi-transparent
- Active buttons: White/Gray
- Inactive buttons: Red
- End button: Red

---

## 📝 FILES CHANGED

Only 1 file was modified:
```
mobile_app/lib/features/session/screens/active_session_screen.dart
```

**Changes:**
- Added video display (AgoraVideoView)
- Added control buttons (mute, camera, flip, speaker)
- Added event handlers (user joined/left)
- Added session notes dialog
- Changed UI to dark theme
- Removed old timer/notes layout

---

## 🔄 ROLLBACK (If Needed)

If you need to go back to the old version:

```bash
cd mobile_app
git checkout HEAD -- lib/features/session/screens/active_session_screen.dart
flutter clean
flutter pub get
flutter build apk
```

---

## ✅ SUCCESS CRITERIA

Your rebuild is successful when:

1. ✅ App installs without errors
2. ✅ Session screen shows video UI
3. ✅ Both devices can see each other
4. ✅ All controls work
5. ✅ Session can be ended properly
6. ✅ No crashes or freezes

---

## 🎉 FINAL CHECKLIST

Before considering it complete:

- [ ] App rebuilt successfully
- [ ] Installed on both test devices
- [ ] Session started successfully
- [ ] Video visible on both devices
- [ ] Audio working on both devices
- [ ] All 4 controls tested
- [ ] Session ended successfully
- [ ] Notes saved properly
- [ ] Rating prompt appeared

---

## 🚀 READY TO REBUILD!

Run these commands now:

```bash
cd mobile_app
flutter clean
flutter pub get
flutter build apk --release
flutter install
```

Then test with 2 devices! 🎥

---

## 📞 SUPPORT

If you encounter issues:

1. Check `SESSION_VIDEO_UI_ADDED.md` for details
2. Check `SESSION_VIDEO_QUICK_GUIDE.md` for usage
3. Check `SESSION_SYSTEM_EXPLAINED.md` for concepts
4. Check Agora credentials in `.env` and `app_config.dart`
5. Verify permissions in `AndroidManifest.xml`

---

🎬 **ENJOY YOUR VIDEO CALLING FEATURE!** 🚀
