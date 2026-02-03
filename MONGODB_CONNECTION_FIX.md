# 🔧 MongoDB Connection Fix for Render

## Problem
MongoDB connection is timing out on Render because the connection string is missing the database name.

## Current Connection String (WRONG)
```
mongodb+srv://susipo1611_db_user:etse123@tutorapp.rjkfgsk.mongodb.net/?appName=tutorApp
```

## Correct Connection String (FIXED)
```
mongodb+srv://susipo1611_db_user:etse123@tutorapp.rjkfgsk.mongodb.net/tutorapp?retryWrites=true&w=majority&appName=tutorApp
```

## What Changed?
1. Added `/tutorapp` after `.mongodb.net` - this is the database name
2. Added `retryWrites=true&w=majority` - these are recommended MongoDB Atlas connection options

## Steps to Fix on Render

### 1. Go to Your Render Service
- Open: https://dashboard.render.com
- Click on your service: `tutor-app-backend-wtru`

### 2. Update Environment Variable
- Click on **"Environment"** tab in the left sidebar
- Find the `MONGODB_URI` variable
- Click **"Edit"** button
- Replace the value with:
```
mongodb+srv://susipo1611_db_user:etse123@tutorapp.rjkfgsk.mongodb.net/tutorapp?retryWrites=true&w=majority&appName=tutorApp
```
- Click **"Save Changes"**

### 3. Trigger Manual Deploy
- Go to **"Manual Deploy"** section at the top
- Click **"Deploy latest commit"** button
- Wait for deployment to complete (2-3 minutes)

### 4. Check Logs
After deployment completes:
- Click on **"Logs"** tab
- Look for: `✅ MongoDB Connected`
- You should also see: `✅ Server running on port 10000`

## Expected Success Output
```
⚠️  Firebase credentials not found. Push notifications disabled.
✅ Escrow scheduler started
🚀 Server running on port 10000
📊 Environment: production
🔗 Health check: http://localhost:10000/api/health
🔌 Socket.IO enabled for real-time communication
📅 Starting booking reminder scheduler...
📅 Booking reminder scheduler started
✅ MongoDB Connected
==> Your service is live 🎉
```

## Verify MongoDB Atlas Settings

While you're waiting, double-check MongoDB Atlas:

### 1. Network Access
- Go to: https://cloud.mongodb.com
- Click **"Network Access"** in left sidebar
- Verify `0.0.0.0/0` is **Active** (you already did this ✅)

### 2. Database Access
- Click **"Database Access"** in left sidebar
- Find user: `susipo1611_db_user`
- Verify it has **"Read and write to any database"** permission
- If not, click **"Edit"** and set to **"Atlas admin"** or **"Read and write to any database"**

## After MongoDB Connects Successfully

Once you see `✅ MongoDB Connected` in Render logs:

### Update Mobile App Configuration
```bash
cd mobile_app
```

Edit `lib/core/config/app_config.dart`:
```dart
class AppConfig {
  // Change this line:
  static const String baseUrl = 'http://192.168.1.5:5000/api';
  
  // To this:
  static const String baseUrl = 'https://tutor-app-backend-wtru.onrender.com/api';
  
  // Rest of the file stays the same...
}
```

### Rebuild Mobile App
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Install on Both Phones
The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

Transfer to both phones and install.

## Test the Connection

1. Open app on both phones
2. Login with your test accounts:
   - **Student**: etsebruk amanuel
   - **Tutor**: bubuam13@gmail.com / 123abc
3. Try booking a session
4. Both phones should now connect to the cloud server!

## Troubleshooting

### If MongoDB still doesn't connect:
1. Check MongoDB Atlas user password is exactly: `etse123`
2. Verify the cluster name is: `tutorapp`
3. Try regenerating the connection string from MongoDB Atlas:
   - Go to **"Database"** → Click **"Connect"**
   - Choose **"Connect your application"**
   - Copy the connection string
   - Replace `<password>` with `etse123`
   - Add `/tutorapp` before the `?`

### If Render shows "Service Unavailable":
- Wait 2-3 minutes - Render free tier can take time to start
- Check if service is sleeping (free tier sleeps after 15 min inactivity)
- First request will wake it up (takes 30-60 seconds)

## Next Steps After Success

1. ✅ MongoDB connects on Render
2. ✅ Update mobile app to use Render URL
3. ✅ Rebuild and install on both phones
4. ✅ Test booking flow end-to-end
5. ✅ Test video call between two devices

---

**Current Status**: Waiting for you to update `MONGODB_URI` on Render and redeploy.
