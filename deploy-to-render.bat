@echo off
echo ========================================
echo Deploying to Render via GitHub
echo ========================================
echo.

echo [1/4] Adding all changes to Git...
git add .

echo.
echo [2/4] Committing changes...
git commit -m "Add Help & Support system with admin interaction, notification preferences, and change password features"

echo.
echo [3/4] Pushing to GitHub...
git push origin main

echo.
echo ========================================
echo Deployment Initiated!
echo ========================================
echo.
echo Your code has been pushed to GitHub.
echo Render will automatically detect the changes and deploy.
echo.
echo Next steps:
echo 1. Go to https://dashboard.render.com
echo 2. Find your service
echo 3. Watch the "Events" tab
echo 4. Wait for "Live" status (2-3 minutes)
echo.
echo Changes deployed:
echo - Help and Support system (5 screens)
echo - Notification Preferences
echo - Change Password
echo - Admin panel real data fixes
echo - Tutor earnings analytics
echo.
pause
