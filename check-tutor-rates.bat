@echo off
echo ========================================
echo Checking Tutor Hourly Rates
echo ========================================
echo.

cd server
node scripts/checkTutorRates.js

echo.
echo ========================================
echo.
echo To update a tutor's rate, run:
echo   update-tutor-rate.bat
echo.
pause
