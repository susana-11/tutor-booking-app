@echo off
echo ========================================
echo   Push to GitHub Helper
echo ========================================
echo.
echo IMPORTANT: You need to create the repository on GitHub FIRST!
echo.
echo Step 1: Go to https://github.com
echo Step 2: Click "+" (top right) -^> "New repository"
echo Step 3: Name: tutor-booking-app
echo Step 4: Click "Create repository"
echo.
echo ========================================
echo.
set /p username="Enter your GitHub username: "
echo.
echo Your repository URL will be:
echo https://github.com/%username%/tutor-booking-app.git
echo.
set /p confirm="Is this correct? (y/n): "
if /i "%confirm%" NEQ "y" (
    echo.
    echo Please run this script again with the correct username.
    pause
    exit /b
)
echo.
echo ========================================
echo   Pushing to GitHub...
echo ========================================
echo.
git remote add origin https://github.com/%username%/tutor-booking-app.git
git branch -M main
git push -u origin main
echo.
echo ========================================
if %ERRORLEVEL% EQU 0 (
    echo ✅ SUCCESS! Code pushed to GitHub
    echo.
    echo Next step: Deploy on Render.com
    echo See: 🚀_RENDER_DEPLOYMENT_STEPS.md
) else (
    echo ❌ FAILED! 
    echo.
    echo Common issues:
    echo 1. Repository doesn't exist on GitHub
    echo 2. Wrong username
    echo 3. Need to login to GitHub
    echo.
    echo Make sure you created the repository on GitHub first!
)
echo ========================================
echo.
pause
