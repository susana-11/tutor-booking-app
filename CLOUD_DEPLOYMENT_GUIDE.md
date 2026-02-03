# Cloud Deployment Guide - Render.com (Free Tier)

## Why Cloud Deployment?

- ✅ No need for local network setup
- ✅ Test from anywhere
- ✅ More realistic production environment
- ✅ Persistent server (doesn't stop when you close laptop)
- ✅ Free tier available

## 🚀 Quick Deploy to Render.com

### Step 1: Prepare Your Code

1. Make sure your code is in a Git repository (GitHub, GitLab, or Bitbucket)

2. Update `server/server.js` to use environment PORT:
   ```javascript
   const PORT = process.env.PORT || 5000;
   ```
   (This is already done in your code)

### Step 2: Create Render Account

1. Go to [render.com](https://render.com)
2. Sign up with GitHub (easiest)
3. Authorize Render to access your repository

### Step 3: Deploy Backend

1. Click "New +" → "Web Service"
2. Connect your repository
3. Configure:
   - **Name:** `tutor-app-backend`
   - **Region:** Choose closest to Ethiopia (Europe/Frankfurt or Singapore)
   - **Branch:** `main` or `master`
   - **Root Directory:** `server`
   - **Environment:** `Node`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
   - **Instance Type:** `Free`

4. Add Environment Variables (click "Advanced" → "Add Environment Variable"):
   ```
   MONGODB_URI=mongodb+srv://susipo1611_db_user:etse123@tutorapp.rjkfgsk.mongodb.net/?appName=tutorApp
   JWT_SECRET=your_jwt_secret_key_here_make_it_very_long_and_secure_for_production
   JWT_EXPIRE=7d
   NODE_ENV=production
   EMAIL_HOST=smtp.gmail.com
   EMAIL_PORT=587
   EMAIL_USER=susipo1611@gmail.com
   EMAIL_PASS=xmvvqwgmevpvmwzt
   TWILIO_ACCOUNT_SID=ACf04521461da626c069131dd26a6ab495
   TWILIO_AUTH_TOKEN=40ab70dd4289afcfb9f86e983e13e42d
   TWILIO_PHONE_NUMBER=+251962983362
   AGORA_APP_ID=0ad4c02139aa48b28e813b4e9676ea0a
   AGORA_APP_CERTIFICATE=your_certificate_here_after_enabling
   CHAPA_SECRET_KEY=CHASECK_TEST-gorYsZA15XxnigRNRzTSHOu1alFEE8o9
   CHAPA_PUBLIC_KEY=CHAPUBK_TEST-RgwiC60qsBwJIpPPuNzllVIsBjI9SGn0
   CHAPA_BASE_URL=https://api.chapa.co/v1
   PLATFORM_FEE_PERCENTAGE=10
   MIN_WITHDRAWAL_AMOUNT=100
   ```

5. Update callback URLs with your Render URL (after deployment):
   ```
   CHAPA_CALLBACK_URL=https://tutor-app-backend.onrender.com/api/payments/callback
   CHAPA_RETURN_URL=https://tutor-app-backend.onrender.com/api/payments/success
   FRONTEND_URL=https://tutor-app-backend.onrender.com
   ```

6. Click "Create Web Service"

7. Wait for deployment (5-10 minutes first time)

8. Your API will be at: `https://tutor-app-backend.onrender.com`

### Step 4: Update Mobile App

Update `mobile_app/lib/core/config/app_config.dart`:

```dart
static const String _baseUrlDev = 'https://tutor-app-backend.onrender.com/api';
static const String _baseUrlProd = 'https://tutor-app-backend.onrender.com/api';
```

### Step 5: Rebuild Mobile App

```bash
cd mobile_app
flutter build apk --release
```

Install the new APK on both phones.

## ⚠️ Important Notes

### Free Tier Limitations

1. **Server Spins Down:** After 15 minutes of inactivity, the server goes to sleep
   - First request after sleep takes 30-60 seconds to wake up
   - Solution: Keep the app open or upgrade to paid tier ($7/month)

2. **750 Hours/Month:** Free tier gives 750 hours
   - Enough for testing and small usage
   - Multiple services share this limit

3. **No Custom Domain:** You get `*.onrender.com` subdomain
   - Fine for testing
   - Can add custom domain on paid tier

### MongoDB Atlas (Already Set Up)

Your MongoDB is already on Atlas (cloud), so no changes needed there.

### Testing After Deployment

1. Test API directly in browser:
   ```
   https://tutor-app-backend.onrender.com/api/subjects
   ```

2. Check logs in Render dashboard for errors

3. Test full flow on both phones

## 🔄 Alternative: Railway.app

Railway is another good option:

1. Go to [railway.app](https://railway.app)
2. Sign up with GitHub
3. Click "New Project" → "Deploy from GitHub repo"
4. Select your repository
5. Add environment variables
6. Deploy

**Pros:**
- $5 free credit per month
- Doesn't spin down
- Faster cold starts

**Cons:**
- Credit runs out faster than Render's 750 hours
- Need credit card for verification

## 🔄 Alternative: Heroku

Heroku is also an option but requires credit card verification even for free tier.

## 📊 Comparison

| Feature | Local Network | Render Free | Railway | Heroku |
|---------|--------------|-------------|---------|--------|
| Setup Time | 5 min | 15 min | 10 min | 15 min |
| Cost | Free | Free | $5/month free | Free (card required) |
| Accessibility | Same WiFi only | Anywhere | Anywhere | Anywhere |
| Spin Down | No | Yes (15 min) | No | Yes (30 min) |
| Best For | Quick testing | Long-term testing | Production-like | Production |

## 🎯 Recommendation

**For immediate testing today:** Use local network (see `LOCAL_NETWORK_TESTING_GUIDE.md`)

**For ongoing testing this week:** Deploy to Render.com (this guide)

**For production:** Consider paid tier on Render ($7/month) or Railway

## 🆘 Need Help?

If you encounter issues:
1. Check Render logs in dashboard
2. Verify all environment variables are set
3. Test MongoDB connection separately
4. Check if server is sleeping (first request slow)
