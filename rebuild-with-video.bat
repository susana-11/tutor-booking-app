@echo off
echo ========================================
echo   REBUILDING APP WITH VIDEO UI
echo ========================================
echo.

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
echo Next Steps:
echo 1. Test with 2 devices
echo 2. Start a session
echo 3. Check video UI appears
echo 4. Test all controls
echo.
echo See VIDEO_UI_COMPLETE.md for details
echo.
pause
