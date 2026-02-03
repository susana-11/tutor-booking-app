# Mobile App Connection Timeout Issue

## Problem Summary
The mobile app times out on ALL HTTP requests (both local and cloud servers) even though:
- Phone's browser CAN reach both servers successfully
- Phone has working WiFi and internet
- Servers are running and responding correctly

## Root Cause
**Dio HTTP client on Android is unable to make network requests.** This is an Android-specific configuration issue.

## Evidence from Logs
```
I/flutter: 🌐 POST Request: https://tutor-app-backend-wtru.onrender.com/api/auth/login
I/flutter: ❌ POST Request failed: DioException [receive timeout]: The request took longer than 0:01:30.000000 to receive data
```

The request never reaches the server - it times out at the client side.

## Attempted Solutions
1. ✅ Added network security config for cleartext traffic
2. ✅ Added INTERNET permission in AndroidManifest
3. ✅ Increased timeout to 90 seconds
4. ✅ Tested with both HTTP (local) and HTTPS (cloud)
5. ✅ Verified servers are accessible from phone's browser

## Likely Causes
1. **Android Network Security Policy** - Android 9+ blocks certain network configurations
2. **Dio Bad Certificate Callback** - Missing certificate validation bypass for development
3. **Android VPN/Proxy** - Phone might have VPN or proxy blocking app traffic
4. **App-specific network restrictions** - Android might be blocking this specific app

## Solution Options

### Option 1: Add Bad Certificate Callback (Quick Fix)
Add this to `mobile_app/lib/core/services/api_service.dart`:

```dart
import 'dart:io';

void initialize() {
  // Allow bad certificates for development
  (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = 
    (HttpClient client) {
    client.badCertificateCallback = 
      (X509Certificate cert, String host, int port) => true;
    return client;
  };
  
  _dio = Dio(BaseOptions(
    baseUrl: AppConfig.instance.baseUrl,
    // ... rest of config
  ));
}
```

### Option 2: Check Phone Settings
1. Go to Settings → Apps → Tutor Booking App
2. Check "Data usage" - ensure background data is allowed
3. Check if any VPN or proxy is active
4. Try disabling "Data Saver" mode if enabled

### Option 3: Use Different HTTP Client
Replace Dio with `http` package which has better Android compatibility.

### Option 4: Test on Different Device
Try installing on another Android device to isolate if it's device-specific.

## Next Steps
1. Implement Option 1 (bad certificate callback)
2. Rebuild and test
3. If still fails, check phone settings (Option 2)
4. Consider switching HTTP client if problem persists

## Status
🔴 **BLOCKED** - App cannot make any network requests on Android device
