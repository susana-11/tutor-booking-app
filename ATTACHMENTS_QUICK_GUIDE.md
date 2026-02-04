# 📎 Chat Attachments Quick Guide

## 🚀 Quick Start

### To Share Document:
1. Tap **+** button
2. Select **"Document"**
3. Choose file
4. **Send**

### To Share Location:
1. Tap **+** button
2. Select **"Location"**
3. Grant permission
4. **Auto-send**

### To Share Contact:
1. Tap **+** button
2. Select **"Contact"**
3. Grant permission
4. Select contact
5. **Send**

### To Schedule Session:
1. Tap **+** button
2. Select **"Schedule"**
3. **Confirm**

---

## 📋 Features at a Glance

| Feature | Icon | Supported Types | Max Size |
|---------|------|-----------------|----------|
| Camera | 📷 | JPG, PNG | 10MB |
| Gallery | 🖼️ | JPG, PNG, GIF | 10MB |
| Document | 📄 | PDF, DOC, XLS, PPT | 10MB |
| Location | 📍 | GPS Coordinates | - |
| Contact | 📇 | Name, Phone | - |
| Schedule | 📅 | Booking Request | - |

---

## 🔧 Required Permissions

### Android:
- ✅ Camera
- ✅ Storage
- ✅ Location
- ✅ Contacts

### iOS (Need to add to Info.plist):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to share it in chat</string>

<key>NSContactsUsageDescription</key>
<string>We need access to your contacts to share them in chat</string>
```

---

## 📦 New Packages

```yaml
file_picker: ^6.1.1
flutter_contacts: ^1.1.7+1
```

---

## 🧪 Quick Test

```bash
# Install dependencies
flutter pub get

# Build and install
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk

# Test each feature
1. Document ✓
2. Location ✓
3. Contact ✓
4. Schedule ✓
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied | Go to Settings → App → Permissions |
| File too large | Max 10MB, compress file |
| Location not found | Enable GPS, wait a moment |
| No contacts | Grant contacts permission |

---

## 📱 Test Accounts

- **Student:** `etsebruk@example.com` / `123abc`
- **Tutor:** `bubuam13@gmail.com` / `123abc`

---

**Status:** ✅ Ready for Testing
**Date:** February 3, 2026
