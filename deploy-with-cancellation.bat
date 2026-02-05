@echo off
echo ========================================
echo  Deploying Payment + Cancellation Features
echo ========================================
echo.

echo Features included:
echo  1. Chapa Payment Integration
echo  2. Escrow System (10-min dispute window)
echo  3. Cancellation and Refund Policy (1-hour for testing)
echo.

echo Step 1: Committing changes to Git...
git add .
git commit -m "Add payment integration and cancellation policy with refund rules"
echo.

echo Step 2: Pushing to GitHub...
git push origin main
echo.

echo Step 3: Render will auto-deploy the backend
echo Please wait 2-3 minutes for deployment to complete
echo.

echo Step 4: Rebuild mobile app
echo Navigate to mobile_app directory and run:
echo   cd mobile_app
echo   flutter clean
echo   flutter pub get
echo   flutter run
echo.

echo ========================================
echo  Deployment Complete!
echo ========================================
echo.

echo Next Steps:
echo 1. Wait for Render deployment (check dashboard)
echo 2. Rebuild mobile app (see above)
echo 3. Test payment flow (see PAYMENT_FLOW_QUICK_TEST.md)
echo 4. Test cancellation (see CANCELLATION_QUICK_TEST.md)
echo.

echo Documentation:
echo - CHAPA_PAYMENT_INTEGRATION_COMPLETE.md
echo - CANCELLATION_REFUND_POLICY_COMPLETE.md
echo - PAYMENT_FLOW_QUICK_TEST.md
echo - CANCELLATION_QUICK_TEST.md
echo.

pause
