# Firebase Setup for Push Notifications

## Overview
This guide will help you set up Firebase for push notifications in the mobile app.

## Prerequisites
- Firebase account
- Android Studio (for Android)
- Xcode (for iOS)

## Steps

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "Tutor Booking App"
4. Follow the setup wizard

### 2. Add Android App

1. In Firebase Console, click "Add app" → Android
2. Enter package name: `com.example.tutor_booking_app`
3. Download `google-services.json`
4. Place it in: `mobile_app/android/app/google-services.json`

5. Update `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

6. Update `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

### 3. Add iOS App

1. In Firebase Console, click "Add app" → iOS
2. Enter bundle ID: `com.example.tutorBookingApp`
3. Download `GoogleService-Info.plist`
4. Open Xcode: `mobile_app/ios/Runner.xcworkspace`
5. Drag `GoogleService-Info.plist` into Runner folder
6. Ensure "Copy items if needed" is checked

7. Update `ios/Podfile`:
```ruby
platform :ios, '12.0'

# Add at the end
pod 'Firebase/Messaging'
```

8. Run: `cd ios && pod install`

### 4. Enable Cloud Messaging

1. In Firebase Console, go to Project Settings
2. Click "Cloud Messaging" tab
3. Note your Server Key (for backend)

### 5. Update Backend

Add to `server/.env`:
```env
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"your-project-id",...}
```

To get the service account JSON:
1. Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Download JSON file
4. Convert to single-line string and add to .env

### 6. Test

1. Run the app: `flutter run`
2. Check logs for: `✅ Firebase initialized`
3. Check logs for: `📱 FCM Token: ...`
4. Create a booking to test notifications

## Troubleshooting

### Android
- Ensure `google-services.json` is in correct location
- Run `flutter clean && flutter pub get`
- Check package name matches Firebase

### iOS
- Ensure `GoogleService-Info.plist` is added to Xcode project
- Run `pod install` in ios folder
- Check bundle ID matches Firebase
- Enable Push Notifications capability in Xcode

### General
- Check Firebase Console for errors
- Verify server has Firebase credentials
- Check device has internet connection
- Ensure notification permissions are granted

## Without Firebase

The app will work without Firebase! You'll still get:
- Real-time notifications via Socket.IO
- In-app notification center
- All notification features

You just won't get push notifications when the app is closed.
