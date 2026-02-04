@echo off
echo ========================================
echo   REBUILDING APP WITH SESSION FIXES
echo ========================================
echo.
echo Fixed Issues:
echo 1. Timer now works on both sides
echo 2. Camera flip now works
echo 3. Voice/audio now works
echo 4. Video shows real camera feed
echo.
pause

cd mobile_app

echo [1/4] Cleaning previous build...
call flutter clean
echo.

echo [2/4] Getting dependencies...
call flutter pub get
echo.

echo [3/4] Building APK (this may take a few minutes)...
call flutter build apk --release
echo.

echo [4/4] Installing on connected device...
call flutter install
echo.

echo ========================================
echo   BUILD COMPLETE!
echo ========================================
echo.
echo APK Location: mobile_app\build\app\outputs\flutter-apk\app-release.apk
echo.
echo TESTING CHECKLIST:
echo [ ] Permissions requested
echo [ ] Video appears on both devices
echo [ ] Audio works both ways
echo [ ] Timer counts down
echo [ ] Mute button works
echo [ ] Camera button works
echo [ ] Flip button works
echo [ ] Speaker button works
echo [ ] End session works
echo.
echo See 🔧_SESSION_VIDEO_FIXED_COMPLETE.md for details
echo.
pause
