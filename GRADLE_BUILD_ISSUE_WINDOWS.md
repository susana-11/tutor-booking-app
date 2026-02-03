# Gradle Build Issue on Windows - Path Length Problem

## Issue
The Flutter/Gradle build is failing due to Windows path length limitations. File paths in the build directory exceed the 260-character limit, causing build failures.

## Root Cause
Windows has a maximum path length of 260 characters by default. The Gradle build cache creates deeply nested directories with long file names that exceed this limit.

## Error Symptoms
- `Could not find a part of the path` errors
- `The directory is not empty` errors when trying to delete build folders
- Kotlin daemon compilation failures
- Storage registration errors in incremental caches

## Solutions

### Option 1: Enable Long Path Support (Recommended)
1. Open Registry Editor (regedit) as Administrator
2. Navigate to: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem`
3. Set `LongPathsEnabled` to `1`
4. Restart your computer
5. Run `flutter clean` and rebuild

### Option 2: Move Project to Shorter Path
Move the project to a location with a shorter path:
```bash
# Instead of: D:\tutorapp\mobile_app
# Use: C:\app
```

### Option 3: Use Existing APK
The payment initialization is working correctly on the backend. The only change needed is the AndroidManifest.xml update for URL launching. You can:
1. Test with the existing APK (URL launcher may not work)
2. Or manually edit the AndroidManifest.xml on a device/emulator

### Option 4: Build on Linux/Mac
If available, build the app on a Linux or Mac system where path length is not an issue.

## What Was Fixed

### Backend (✅ Complete)
1. Payment initialization - Fixed tutorId handling
2. Booking creation - Now stores TutorProfile ID correctly
3. Payment service - Added validation and error handling
4. Existing bookings - Fixed with script

### Mobile App (⚠️ Needs Rebuild)
1. AndroidManifest.xml - Added URL launcher queries
2. Payment service - Improved URL launching logic
3. Removed webview_flutter to avoid build issues

## Current Status

✅ **Payment initialization works** - Backend successfully generates checkout URLs
✅ **Booking creation fixed** - TutorId now stored correctly
⚠️ **URL launching** - Needs app rebuild to apply AndroidManifest changes

## Testing Without Rebuild

You can test the payment flow partially:
1. The payment initialization will work and return a checkout URL
2. The URL won't open in the browser (needs AndroidManifest fix)
3. You can manually copy the URL and open it in a browser
4. Complete the payment
5. The backend will verify and update the booking

## Next Steps

1. **Enable long paths** on Windows (recommended)
2. **Rebuild the app** with `flutter clean` and `flutter run`
3. **Test payment flow** end-to-end
4. **Verify** booking status updates after payment

## Files Modified
- `server/routes/bookings.js` - Fixed tutorId handling
- `server/services/paymentService.js` - Added validation
- `mobile_app/android/app/src/main/AndroidManifest.xml` - Added URL queries
- `mobile_app/lib/core/services/payment_service.dart` - Improved URL launching
- `mobile_app/pubspec.yaml` - Removed webview_flutter

## Alternative: Manual Testing

To test without rebuilding:
1. Get the checkout URL from the API response
2. Copy it manually
3. Open in a browser
4. Complete payment with test card
5. Verify booking status in database

Test Card Details (Chapa):
- Card: 5200000000000007
- Expiry: Any future date
- CVV: Any 3 digits
