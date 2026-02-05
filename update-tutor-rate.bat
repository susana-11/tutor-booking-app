@echo off
echo ========================================
echo Update Tutor Hourly Rate
echo ========================================
echo.

cd server
node scripts/updateTutorRate.js

pause
