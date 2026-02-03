# 🚀 Render.com Deployment - Complete Guide

## ✅ Step 1: Push Code to GitHub (REQUIRED)

Your code is now committed to Git locally. You need to push it to GitHub.

### Option A: Create New Repository on GitHub

1. **Go to GitHub.com and login**
   - Visit: https://github.com

2. **Create New Repository:**
   - Click the "+" icon (top right) → "New repository"
   - Repository name: `tutor-booking-app`
   - Description: "Complete tutor booking platform with Flutter mobile app"
   - **Keep it Private** (recommended) or Public
   - **DO NOT** initialize with README (we already have code)
   - Click "Create repository"

3. **Push Your Code:**
   
   Copy the commands GitHub shows you, or use these:
   
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/tutor-booking-app.git
   git branch -M main
   git push -u origin main
   ```
   
   Replace `YOUR_USERNAME` with your GitHub username.

### Option B: Use Existing Repository

If you already have a GitHub repository:

```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main
```

---

## ✅ Step 2: Sign Up for Render.com

1. **Go to Render.com:**
   - Visit: https://render.com

2. **Sign Up with GitHub:**
   - Click "Get Started for Free"
   - Click "Sign up with GitHub"
   - Authorize Render to access your GitHub account
   - This makes deployment much easier!

---

## ✅ Step 3: Create Web Service on Render

1. **Click "New +" → "Web Service"**

2. **Connect Repository:**
   - You'll see your GitHub repositories
   - Find and select: `tutor-booking-app`
   - Click "Connect"

3. **Configure Service:**
   
   Fill in these settings:
   
   | Setting | Value |
   |---------|-------|
   | **Name** | `tutor-app-backend` |
   | **Region** | Choose closest to Ethiopia (Europe/Frankfurt or Singapore) |
   | **Branch** | `main` |
   | **Root Directory** | `server` |
   | **Environment** | `Node` |
   | **Build Command** | `npm install` |
   | **Start Command** | `npm start` |
   | **Instance Type** | `Free` |

4. **Click "Advanced" to add Environment Variables**

---

## ✅ Step 4: Add Environment Variables

Click "Add Environment Variable" for each of these:

### Required Variables:

```
MONGODB_URI=mongodb+srv://susipo1611_db_user:etse123@tutorapp.rjkfgsk.mongodb.net/?appName=tutorApp

JWT_SECRET=your_jwt_secret_key_here_make_it_very_long_and_secure_for_production

JWT_EXPIRE=7d

NODE_ENV=production

PORT=5000

EMAIL_HOST=smtp.gmail.com

EMAIL_PORT=587

EMAIL_USER=susipo1611@gmail.com

EMAIL_PASS=xmvvqwgmevpvmwzt

TWILIO_ACCOUNT_SID=ACf04521461da626c069131dd26a6ab495

TWILIO_AUTH_TOKEN=40ab70dd4289afcfb9f86e983e13e42d

TWILIO_PHONE_NUMBER=+251962983362

AGORA_APP_ID=0ad4c02139aa48b28e813b4e9676ea0a

AGORA_APP_CERTIFICATE=your_certificate_here

CHAPA_SECRET_KEY=CHASECK_TEST-gorYsZA15XxnigRNRzTSHOu1alFEE8o9

CHAPA_PUBLIC_KEY=CHAPUBK_TEST-RgwiC60qsBwJIpPPuNzllVIsBjI9SGn0

CHAPA_BASE_URL=https://api.chapa.co/v1

PLATFORM_FEE_PERCENTAGE=10

MIN_WITHDRAWAL_AMOUNT=100
```

**Note:** You'll update callback URLs after deployment (Step 6)

---

## ✅ Step 5: Deploy!

1. **Click "Create Web Service"**

2. **Wait for Deployment (5-10 minutes first time)**
   
   You'll see:
   - "Build in progress..."
   - "Installing dependencies..."
   - "Starting service..."
   - "Live" ✅

3. **Your API URL will be:**
   ```
   https://tutor-app-backend.onrender.com
   ```
   
   (The exact URL will be shown in Render dashboard)

---

## ✅ Step 6: Update Callback URLs

After deployment, you need to update these environment variables:

1. **In Render Dashboard:**
   - Go to your service
   - Click "Environment" tab
   - Click "Add Environment Variable"

2. **Add these (replace with YOUR actual Render URL):**

```
CHAPA_CALLBACK_URL=https://tutor-app-backend.onrender.com/api/payments/callback

CHAPA_RETURN_URL=https://tutor-app-backend.onrender.com/api/payments/success

FRONTEND_URL=https://tutor-app-backend.onrender.com
```

3. **Click "Save Changes"**
   - Service will automatically redeploy (takes 1-2 minutes)

---

## ✅ Step 7: Test Your Deployed API

1. **Open browser and visit:**
   ```
   https://tutor-app-backend.onrender.com
   ```
   
   You should see: `{"message":"Route not found"}`
   
   ✅ This means server is working!

2. **Test a specific endpoint:**
   ```
   https://tutor-app-backend.onrender.com/api/subjects
   ```
   
   Should return list of subjects

---

## ✅ Step 8: Update Mobile App

Now update your Flutter app to use the deployed API:

1. **Edit `mobile_app/lib/core/config/app_config.dart`:**

```dart
// Replace this line:
static const String _baseUrlDev = 'http://192.168.1.5:5000/api';

// With your Render URL:
static const String _baseUrlDev = 'https://tutor-app-backend.onrender.com/api';
static const String _baseUrlProd = 'https://tutor-app-backend.onrender.com/api';
```

2. **Rebuild the app:**

```bash
cd mobile_app
flutter build apk --release
```

3. **Install on both phones:**
   - APK location: `mobile_app\build\app\outputs\flutter-apk\app-release.apk`
   - Transfer and install on both phones

---

## ✅ Step 9: Test Everything!

Now your app works from anywhere (no WiFi issues!):

1. **Phone 1 (Student):**
   - Login
   - Search tutors
   - Book session
   - Pay

2. **Phone 2 (Tutor):**
   - Login
   - Accept booking
   - Start session

3. **Both:**
   - Video call
   - Chat
   - End session
   - Rate

---

## 🎯 Your Deployed URLs

After deployment, you'll have:

```
Backend API: https://tutor-app-backend.onrender.com
API Endpoints: https://tutor-app-backend.onrender.com/api/*
```

---

## ⚠️ Important Notes

### Free Tier Limitations:

1. **Server Spins Down:**
   - After 15 minutes of inactivity, server goes to sleep
   - First request after sleep takes 30-60 seconds
   - Subsequent requests are fast
   - **Solution:** Keep app open or upgrade to paid tier ($7/month)

2. **750 Hours/Month:**
   - Free tier gives 750 hours
   - Enough for testing and light usage
   - Resets every month

3. **Automatic Deploys:**
   - Every time you push to GitHub, Render auto-deploys
   - Takes 2-3 minutes

### To Update Your App:

1. Make changes locally
2. Commit: `git add . && git commit -m "Your message"`
3. Push: `git push`
4. Render automatically deploys!

---

## 🔧 Troubleshooting

### "Build Failed"

**Check Render logs:**
- Go to service → "Logs" tab
- Look for error messages
- Common issues:
  - Missing environment variables
  - Wrong root directory (should be `server`)
  - npm install errors

**Fix:**
- Add missing environment variables
- Check "Root Directory" is set to `server`
- Redeploy

### "Service Unavailable"

**First request after sleep:**
- Wait 30-60 seconds
- Try again
- This is normal for free tier

**Actual error:**
- Check logs in Render dashboard
- Look for MongoDB connection errors
- Verify environment variables

### "Cannot connect from app"

**Check mobile app config:**
- Make sure you updated `app_config.dart`
- URL should be: `https://tutor-app-backend.onrender.com/api`
- Rebuild app after changing config

**Test in browser first:**
- Visit: `https://tutor-app-backend.onrender.com`
- Should see: `{"message":"Route not found"}`

---

## 📊 Monitoring

### View Logs:

1. Go to Render dashboard
2. Click your service
3. Click "Logs" tab
4. See real-time logs

### Check Status:

- Green "Live" badge = Working
- Yellow "Building" = Deploying
- Red "Failed" = Error (check logs)

---

## 💰 Upgrade Options

If you need better performance:

### Render Paid Tier ($7/month):
- No spin down
- Faster performance
- More hours
- Custom domain support

### To Upgrade:
1. Go to service settings
2. Change instance type from "Free" to "Starter"
3. Add payment method

---

## ✅ Checklist

Before testing, verify:

- [ ] Code pushed to GitHub
- [ ] Render service created
- [ ] All environment variables added
- [ ] Callback URLs updated
- [ ] Service shows "Live" status
- [ ] Browser test works
- [ ] Mobile app config updated
- [ ] App rebuilt and installed

---

## 🎉 You're Done!

Your app is now deployed to the cloud and accessible from anywhere!

**No more:**
- ❌ WiFi issues
- ❌ Local network setup
- ❌ Firewall problems
- ❌ IP address changes

**Now you have:**
- ✅ Global access
- ✅ HTTPS security
- ✅ Automatic deploys
- ✅ Professional setup

Test your app and enjoy! 🚀
