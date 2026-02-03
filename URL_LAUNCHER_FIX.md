# URL Launcher Fix for Payment Page

## Problem
The payment initialization was successful and returned a checkout URL, but the mobile app couldn't open it:
```
I/UrlLauncher( 5694): component name for https://checkout.chapa.co is null
I/flutter ( 5694): Could not launch payment URL
```

## Root Cause
Android 11+ requires explicit query declarations in the AndroidManifest.xml for URL schemes that the app wants to launch. Without these declarations, `canLaunchUrl()` returns false even for valid URLs.

## Fixes Applied

### 1. AndroidManifest.xml
Added URL launcher queries to allow the app to open HTTP/HTTPS URLs:

```xml
<queries>
    <!-- Existing query -->
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
    
    <!-- URL launcher queries -->
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="http" />
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="https" />
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="tel" />
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="mailto" />
    </intent>
</queries>
```

### 2. Payment Service (payment_service.dart)
Updated the `openPaymentPage` method to:
- Try launching directly without checking `canLaunchUrl()` first
- Add fallback to `LaunchMode.platformDefault` if `externalApplication` fails
- Add better logging for debugging

```dart
Future<bool> openPaymentPage(String checkoutUrl) async {
  try {
    print('🌐 Attempting to open URL: $checkoutUrl');
    final Uri url = Uri.parse(checkoutUrl);
    
    // Try to launch directly
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      print('✅ URL launched: $launched');
      return launched;
    } catch (e) {
      // Fallback: try with platformDefault mode
      final launched = await launchUrl(
        url,
        mode: LaunchMode.platformDefault,
      );
      return launched;
    }
  } catch (e) {
    print('❌ Open payment page error: $e');
    return false;
  }
}
```

## Testing Steps

1. **Rebuild the app** (required for AndroidManifest changes):
   ```bash
   cd mobile_app
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test payment flow**:
   - Create a booking
   - Click "Pay Now"
   - The Chapa payment page should open in the browser
   - Complete the payment
   - Return to the app

## Expected Behavior
- Payment URL should open in the default browser
- User can complete payment on Chapa's website
- After payment, user can return to the app
- Booking status should update to "paid"

## Alternative Solution (If Still Not Working)
If the URL still doesn't open, you can use an in-app WebView instead:

1. Add `webview_flutter` to pubspec.yaml
2. Create a WebView screen to display the payment page
3. Navigate to that screen instead of launching external URL

## Files Modified
- `mobile_app/android/app/src/main/AndroidManifest.xml` - Added URL launcher queries
- `mobile_app/lib/core/services/payment_service.dart` - Improved URL launching logic

## Notes
- The AndroidManifest changes require a full rebuild (`flutter clean` + `flutter run`)
- The payment initialization is working correctly on the backend
- The checkout URL is valid and accessible
- This is purely a mobile app URL launching configuration issue
