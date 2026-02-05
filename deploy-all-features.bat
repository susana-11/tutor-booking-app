@echo off
echo ========================================
echo  Deploying All Features
echo ========================================
echo.

echo Features included in this deployment:
echo.
echo  1. Chapa Payment Integration
echo     - Secure payment via Chapa
echo     - Escrow system (10-min dispute window)
echo     - Automatic payment release
echo.
echo  2. Cancellation and Refund Policy
echo     - Time-based refunds (1 hour for testing)
echo     - Tutor cancellation = 100%% refund
echo     - Session protection
echo.
echo  3. Enhanced Reschedule System
echo     - Session type changes
echo     - Location updates
echo     - Price adjustments
echo     - Reschedule limits (3 attempts)
echo     - Minimum notice (1 hour)
echo.

echo ========================================
echo  Step 1: Committing to Git
echo ========================================
git add .
git commit -m "Add payment, cancellation, and enhanced reschedule features - All testing ready"
echo.

echo ========================================
echo  Step 2: Pushing to GitHub
echo ========================================
git push origin main
echo.

echo ========================================
echo  Step 3: Backend Deployment
echo ========================================
echo Render will automatically deploy the backend
echo Please wait 2-3 minutes for deployment to complete
echo Check Render dashboard for deployment status
echo.

echo ========================================
echo  Step 4: Mobile App Rebuild
echo ========================================
echo Navigate to mobile_app directory and run:
echo.
echo   cd mobile_app
echo   flutter clean
echo   flutter pub get
echo   flutter run
echo.

echo ========================================
echo  Testing Configuration (Current)
echo ========================================
echo.
echo Payment:
echo   - Dispute window: 10 minutes
echo   - Escrow release: 10 min after session
echo.
echo Cancellation:
echo   - Full refund: 1+ hours before
echo   - Partial refund: 30min - 1hr before
echo   - No refund: less than 30 minutes before
echo.
echo Reschedule:
echo   - Minimum notice: 1 hour before
echo   - Maximum attempts: 3 per booking
echo.

echo ========================================
echo  Testing Guides
echo ========================================
echo.
echo 1. Payment Flow:
echo    - See PAYMENT_FLOW_QUICK_TEST.md
echo.
echo 2. Cancellation:
echo    - See CANCELLATION_QUICK_TEST.md
echo.
echo 3. Reschedule:
echo    - See RESCHEDULE_ENHANCED_COMPLETE.md
echo.
echo 4. Complete Summary:
echo    - See ALL_FEATURES_COMPLETE_SUMMARY.md
echo.

echo ========================================
echo  Production Deployment
echo ========================================
echo.
echo To change to production configuration:
echo.
echo 1. Update Render environment variables:
echo    - ESCROW_RELEASE_DELAY_MINUTES=1440
echo    - ESCROW_REFUND_FULL_HOURS=24
echo    - ESCROW_REFUND_PARTIAL_HOURS=12
echo    - RESCHEDULE_MIN_NOTICE_HOURS=12
echo.
echo 2. Restart Render service
echo.

echo ========================================
echo  Deployment Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Wait for Render deployment (2-3 minutes)
echo 2. Rebuild mobile app (see above)
echo 3. Test all features (see testing guides)
echo 4. Monitor logs for errors
echo 5. Gather user feedback
echo.

pause
