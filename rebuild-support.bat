@echo off
echo ========================================
echo Rebuilding App with Support System
echo ========================================
echo.

cd mobile_app

echo [1/4] Cleaning build...
call flutter clean

echo.
echo [2/4] Getting dependencies...
call flutter pub get

echo.
echo [3/4] Building app...
call flutter build apk --debug

echo.
echo [4/4] Installing on device...
call flutter install

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo The app has been rebuilt with the Help and Support system.
echo You can now test:
echo - Create Support Ticket
echo - My Tickets
echo - FAQs
echo.
pause
