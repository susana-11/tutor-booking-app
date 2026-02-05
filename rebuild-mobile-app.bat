@echo off
echo ========================================
echo Rebuilding Mobile App
echo ========================================
echo.

echo [1/3] Cleaning build cache...
cd mobile_app
call flutter clean

echo.
echo [2/3] Getting dependencies...
call flutter pub get

echo.
echo [3/3] Running app...
call flutter run

echo.
echo ========================================
echo Mobile App Rebuilt!
echo ========================================
pause
