@echo off
echo Installing Cloudinary packages...
cd server
npm install cloudinary multer-storage-cloudinary
echo.
echo ✅ Cloudinary packages installed!
echo.
echo Next steps:
echo 1. Update Render environment variables (see CLOUDINARY_IMPLEMENTATION_COMPLETE.md)
echo 2. Push code to GitHub: git push origin main
echo 3. Wait for Render to deploy (3-5 minutes)
echo 4. Test on mobile - images will never disappear again!
echo.
pause
