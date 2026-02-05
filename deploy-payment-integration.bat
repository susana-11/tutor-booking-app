@echo off
echo ========================================
echo  Deploying Chapa Payment Integration
echo ========================================
echo.

echo Step 1: Committing changes to Git...
git add .
git commit -m "Integrate Chapa payment with escrow system - 10 minute dispute window"
echo.

echo Step 2: Pushing to GitHub...
git push origin main
echo.

echo Step 3: Render will auto-deploy the backend
echo Please wait 2-3 minutes for deployment to complete
echo.

echo Step 4: Rebuild mobile app
echo Navigate to mobile_app directory and run:
echo   flutter clean
echo   flutter pub get
echo   flutter run
echo.

echo ========================================
echo  Deployment Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Wait for Render deployment to complete
echo 2. Rebuild mobile app (see above)
echo 3. Test payment flow (see CHAPA_PAYMENT_INTEGRATION_COMPLETE.md)
echo.

pause
