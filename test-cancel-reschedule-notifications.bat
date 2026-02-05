@echo off
echo Testing Cancel and Reschedule Notifications...
echo.
cd server
node scripts/testCancelRescheduleNotifications.js
cd ..
pause
