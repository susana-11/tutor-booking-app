# Flutter Rebuild Commands

## Quick Rebuild (Recommended)
```bash
cd mobile_app
flutter clean
flutter pub get
flutter build apk --release
```

## Debug Build (Faster, for testing)
```bash
cd mobile_app
flutter clean
flutter pub get
flutter run
```

## Full Clean Rebuild
```bash
cd mobile_app
flutter clean
flutter pub get
flutter pub upgrade
flutter build apk --release
```

## Build APK Only (No Install)
```bash
cd mobile_app
flutter build apk --release
```

## Build and Install on Connected Device
```bash
cd mobile_app
flutter clean
flutter pub get
flutter install
```

## Check for Issues Before Building
```bash
cd mobile_app
flutter doctor
flutter analyze
```

## Build Smaller APK (Split by ABI)
```bash
cd mobile_app
flutter build apk --split-per-abi --release
```

## Output Location
After building, the APK will be located at:
```
mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

## Windows Batch File
You can also use the existing batch file:
```bash
rebuild-mobile-app.bat
```

---

## Current Situation
**No rebuild needed!** The reschedule authorization fix was server-side only. The changes have been auto-deployed to Render and are already live.

## When to Rebuild
You only need to rebuild the mobile app when:
- Dart/Flutter code changes in `mobile_app/lib/`
- Dependencies change in `pubspec.yaml`
- Assets are added/modified
- Android/iOS native code changes

Server-side changes (Node.js/Express) don't require mobile app rebuilds.
