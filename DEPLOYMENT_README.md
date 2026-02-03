# Tutor Booking App - Deployment Guide

## 🚀 Quick Deploy to Render.com

This repository contains a complete tutor booking platform with:
- Node.js/Express backend
- Flutter mobile app
- React admin panel
- MongoDB database
- Real-time chat & video calls
- Payment integration (Chapa)

### Backend Deployment (Render.com)

1. **Fork/Push this repo to GitHub**

2. **Go to [render.com](https://render.com) and sign up**

3. **Create New Web Service:**
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Configure:
     - **Name:** `tutor-app-backend`
     - **Region:** Choose closest to your location
     - **Branch:** `main` or `master`
     - **Root Directory:** `server`
     - **Environment:** `Node`
     - **Build Command:** `npm install`
     - **Start Command:** `npm start`
     - **Instance Type:** `Free`

4. **Add Environment Variables:**
   ```
   MONGODB_URI=your_mongodb_atlas_connection_string
   JWT_SECRET=your_jwt_secret_key_here
   JWT_EXPIRE=7d
   NODE_ENV=production
   PORT=5000
   EMAIL_HOST=smtp.gmail.com
   EMAIL_PORT=587
   EMAIL_USER=your_email@gmail.com
   EMAIL_PASS=your_app_password
   TWILIO_ACCOUNT_SID=your_twilio_sid
   TWILIO_AUTH_TOKEN=your_twilio_token
   TWILIO_PHONE_NUMBER=your_twilio_phone
   AGORA_APP_ID=your_agora_app_id
   AGORA_APP_CERTIFICATE=your_agora_certificate
   CHAPA_SECRET_KEY=your_chapa_secret
   CHAPA_PUBLIC_KEY=your_chapa_public
   CHAPA_BASE_URL=https://api.chapa.co/v1
   PLATFORM_FEE_PERCENTAGE=10
   MIN_WITHDRAWAL_AMOUNT=100
   ```

5. **Update callback URLs after deployment:**
   ```
   CHAPA_CALLBACK_URL=https://your-app.onrender.com/api/payments/callback
   CHAPA_RETURN_URL=https://your-app.onrender.com/api/payments/success
   FRONTEND_URL=https://your-app.onrender.com
   ```

6. **Deploy!**

### Mobile App Configuration

After backend is deployed, update `mobile_app/lib/core/config/app_config.dart`:

```dart
static const String _baseUrlDev = 'https://your-app.onrender.com/api';
static const String _baseUrlProd = 'https://your-app.onrender.com/api';
```

Then rebuild:
```bash
cd mobile_app
flutter build apk --release
```

### Features

- ✅ User authentication (JWT)
- ✅ Tutor profiles & verification
- ✅ Student search & booking
- ✅ Real-time chat (Socket.io)
- ✅ Video calls (Agora)
- ✅ Payment processing (Chapa)
- ✅ Rating & review system
- ✅ Session management
- ✅ Notifications
- ✅ Admin panel

### Tech Stack

**Backend:**
- Node.js + Express
- MongoDB + Mongoose
- Socket.io
- JWT Authentication
- Multer (file uploads)

**Mobile:**
- Flutter
- Provider (state management)
- Socket.io client
- Agora RTC

**Admin:**
- React
- Material-UI
- Axios

### License

MIT
