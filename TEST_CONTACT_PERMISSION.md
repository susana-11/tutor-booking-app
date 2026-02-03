# 🧪 Test Contact Permission - Step by Step

## Quick Test Commands

### 1. Uninstall Current App
```bash
adb uninstall com.example.tutor_booking_app
```

### 2. Clean Build
```bash
cd mobile_app
flutter clean
```

### 3. Rebuild and Run
```bash
flutter run
```

## Manual Testing Steps

### Test 1: Check Permission Declaration
```bash
# Extract AndroidManifest from APK
cd mobile_app/build/app/outputs/flutter-apk
unzip -p app-release.apk AndroidManifest.xml | grep READ_CONTACTS
```

Expected output: Should show `READ_CONTACTS` permission

### Test 2: Check Runtime Permission
When you tap "Contact" button, watch the console for these logs:

```
🔍 Starting contact share...
📱 Requesting contacts permission...
```

**If you see:** `✅ Permission result: true` → Permission granted
**If you see:** `❌ Permission denied` → Permission was denied

### Test 3: Check Contacts Fetch
After permission is granted:

```
📋 Fetching contacts...
📋 Found X contacts
```

**If X = 0:** Your device has no contacts
**If X > 0:** Contacts were fetched successfully

## Common Issues & Solutions

### Issue 1: Permission Dialog Doesn't Show
**Cause:** App was installed before permission was added to manifest
**Solution:** 
```bash
adb uninstall com.example.tutor_booking_app
flutter run
```

### Issue 2: Permission Granted but No Contacts
**Cause:** Device has no contacts saved
**Solution:** Add test contacts to your device:
1. Open Contacts app
2. Add a few test contacts
3. Try again

### Issue 3: "Permission Required" Error After Granting
**Cause:** Permission not properly processed
**Solution:** 
1. Close the app completely
2. Open device Settings → Apps → Tutor Booking App → Permissions
3. Manually toggle Contacts permission OFF then ON
4. Reopen the app and try again

### Issue 4: Error "Failed to share contact"
**Cause:** Exception during contact fetch
**Solution:** Check console for full error message:
```
❌ Share contact error: [error details]
❌ Error stack trace: [stack trace]
```

## Verify Permission in Device Settings

### Android 11+
1. Settings → Apps → Tutor Booking App
2. Permissions → Contacts
3. Should show "Allowed"

### Android 10 and below
1. Settings → Apps → Tutor Booking App
2. Permissions
3. Contacts should be checked/enabled

## Test on Different Scenarios

### Scenario 1: First Time Permission Request
1. Fresh install
2. Tap Contact button
3. System dialog should appear
4. Tap "Allow"
5. Contact list should appear

### Scenario 2: Permission Previously Denied
1. If you denied permission before
2. Tap Contact button
3. Should show "Open Settings" dialog
4. Tap "Open Settings"
5. Enable Contacts permission
6. Go back to app and try again

### Scenario 3: Permission Already Granted
1. Permission was granted in previous session
2. Tap Contact button
3. Should directly show contact list (no permission dialog)

## Debug Output Example

### Successful Flow:
```
🔍 Starting contact share...
📱 Requesting contacts permission...
✅ Permission result: true
📋 Fetching contacts...
📋 Found 25 contacts
✅ Contact selected: John Doe
```

### Failed Flow (Permission Denied):
```
🔍 Starting contact share...
📱 Requesting contacts permission...
❌ Permission denied
```

### Failed Flow (No Contacts):
```
🔍 Starting contact share...
📱 Requesting contacts permission...
✅ Permission result: true
📋 Fetching contacts...
📋 Found 0 contacts
```

## If Nothing Works

Try this nuclear option:

```bash
# 1. Uninstall app
adb uninstall com.example.tutor_booking_app

# 2. Clean everything
cd mobile_app
flutter clean
rm -rf build/
rm -rf .dart_tool/

# 3. Get dependencies
flutter pub get

# 4. Rebuild
flutter build apk --release

# 5. Install manually
adb install build/app/outputs/flutter-apk/app-release.apk

# 6. Grant permission manually via ADB
adb shell pm grant com.example.tutor_booking_app android.permission.READ_CONTACTS

# 7. Test
```

## Expected Behavior

✅ Tap "Contact" → Permission dialog appears (first time only)
✅ Tap "Allow" → Loading spinner appears
✅ Loading completes → Contact list dialog appears
✅ Select contact → Contact message sent
✅ Success message appears

## Report Back

If still not working, please provide:
1. Console logs (all lines starting with 🔍 📱 ✅ ❌ 📋)
2. Android version of your device
3. Whether permission shows as "Allowed" in device settings
4. Screenshot of the error message
