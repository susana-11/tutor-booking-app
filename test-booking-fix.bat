@echo off
echo ========================================
echo Testing Booking Flow Fix
echo ========================================
echo.

echo Step 1: Creating test availability with session types...
cd server
call node scripts/createTestAvailability.js
echo.

echo Step 2: Checking tutor slots...
call node scripts/checkTutorSlots.js
echo.

echo ========================================
echo Test data created!
echo ========================================
echo.
echo Next steps:
echo 1. Hot reload your Flutter app (press 'r')
echo 2. Login as student
echo 3. Search for a tutor
echo 4. Click "Book Session"
echo 5. Check console logs for "Session Types Count"
echo.
echo If Count = 2: UI should display properly!
echo If Count = 0: Run this script again
echo.
pause
