# 🔧 Contact Permission Fix

## Issue
Contact sharing shows "permission required" error even after granting permission.

## Root Cause
The `READ_CONTACTS` permission was added to AndroidManifest.xml, but the app needs to be **completely rebuilt** for Android to recognize the new permission.

## Solution

### Step 1: Uninstall the Current App
```bash
# This ensures the old permission cache is cleared
adb uninstall com.example.tutor_booking_app
```

OR manually uninstall from your device:
- Long press the app icon
- Select "Uninstall" or "App info" → "Uninstall"

### Step 2: Clean Build Cache
```bash
cd mobile_app
flutter clean
```

### Step 3: Rebuild and Install
```bash
flutter build apk --release
# OR for debug
flutter run
```

### Step 4: Test Contact Sharing
1. Open the app
2. Go to any chat
3. Tap the "+" button
4. Select "Contact"
5. When prompted, tap "Allow" to grant contacts permission
6. You should now see your contacts list

## What Was Fixed in Code

### Added Debug Logging
```dart
print('🔍 Starting contact share...');
print('📱 Requesting contacts permission...');
print('✅ Permission result: $hasPermission');
print('📋 Found ${contacts.length} contacts');
```

### Added Small Delay
After permission is granted, added a 300ms delay to ensure Android processes the permission:
```dart
await Future.delayed(const Duration(milliseconds: 300));
```

### Better Error Handling
- Shows "Open Settings" dialog if permission is denied
- Proper loading states
- Clear error messages

## Verification

After rebuilding, you should see these logs in the console:
```
🔍 Starting contact share...
📱 Requesting contacts permission...
✅ Permission result: true
📋 Fetching contacts...
📋 Found X contacts
✅ Contact selected: [Contact Name]
```

## If Still Not Working

1. **Check Android version**: Android 11+ has stricter permission requirements
2. **Verify permission in settings**:
   - Go to Settings → Apps → Tutor Booking App → Permissions
   - Ensure "Contacts" is set to "Allow"
3. **Check logs**: Look for any error messages in the console
4. **Try on different device**: Some devices have custom permission managers

## Important Notes

⚠️ **Always rebuild after adding new permissions to AndroidManifest.xml**
⚠️ **Uninstalling the app clears all permission caches**
⚠️ **Debug builds and release builds have separate permission states**
