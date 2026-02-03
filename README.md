# Tutor Booking Platform

A comprehensive tutor booking platform with mobile apps for students/tutors and a web dashboard for admins.

## 🏗️ Project Structure

```
tutorapp/
├── mobile_app/          # Flutter mobile app (Students & Tutors)
│   ├── lib/
│   │   ├── features/    # Feature modules (auth, booking, chat, calls)
│   │   └── core/        # Core services, theme, config
│   └── pubspec.yaml
│
├── admin-web/           # React admin dashboard
│   ├── src/
│   │   ├── pages/       # Admin pages
│   │   ├── components/  # Reusable components
│   │   └── contexts/    # React contexts
│   └── package.json
│
└── server/              # Node.js/Express backend
    ├── models/          # MongoDB models
    ├── routes/          # API routes
    ├── controllers/     # Route controllers
    ├── services/        # Business logic
    ├── socket/          # Socket.IO handlers
    └── scripts/         # Setup & utility scripts
```

## ✨ Features

### Mobile App (Students & Tutors)
- 🔐 Authentication (Login, Register, Email Verification)
- 👤 User Profiles (Student & Tutor)
- 🔍 Tutor Search & Filtering
- 📅 Availability Management (Tutors)
- 📚 Booking System (Request, Confirm, Cancel)
- 💬 Real-time Chat (Text, Voice Messages, File Sharing)
- 📞 Voice & Video Calls (Agora integration)
- 🔔 Push & Real-time Notifications (Firebase + Socket.IO)
- 💰 Earnings Tracking (Tutors)

### Admin Dashboard
- 📊 Analytics & Statistics
- 👥 User Management
- ✅ Tutor Verification
- 📖 Subject Management
- 📅 Booking Management
- 💳 Payment Management
- ⚙️ System Settings

### Backend API
- RESTful API with Express.js
- MongoDB database
- JWT authentication
- Socket.IO for real-time features
- Push notifications via Firebase Cloud Messaging
- Agora integration for calls
- Email notifications
- File upload handling
- Automated booking reminders

## 🚀 Getting Started

### Prerequisites
- Node.js (v16+)
- MongoDB
- Flutter SDK (v3.0+)
- Agora account (for video/voice calls)

### 1. Server Setup

```bash
cd server
npm install
cp .env.example .env
# Edit .env with your configuration
node scripts/createAdmin.js
node scripts/createSubjects.js
npm start
```

### 2. Mobile App Setup

```bash
cd mobile_app
flutter pub get
# Update lib/core/config/app_config.dart with your API URL
flutter run
```

### 3. Admin Dashboard Setup

```bash
cd admin-web
npm install
# Update src/config with your API URL
npm start
```

## 📚 Documentation

- [READ_ME_FIRST.md](READ_ME_FIRST.md) - Quick start guide
- [BOOKING_FLOW_GUIDE.md](BOOKING_FLOW_GUIDE.md) - Booking system flow
- [BOOKING_FLOW_DIAGRAM.md](BOOKING_FLOW_DIAGRAM.md) - Visual booking flow
- [AGORA_SETUP_GUIDE.md](AGORA_SETUP_GUIDE.md) - Video/voice call setup
- [NOTIFICATION_SYSTEM_GUIDE.md](NOTIFICATION_SYSTEM_GUIDE.md) - Complete notification system guide
- [NOTIFICATION_IMPLEMENTATION_STATUS.md](NOTIFICATION_IMPLEMENTATION_STATUS.md) - Implementation status

## 🔧 Configuration

### Server Environment Variables
```env
MONGODB_URI=mongodb://localhost:27017/tutor_booking
JWT_SECRET=your_jwt_secret
PORT=5000
AGORA_APP_ID=your_agora_app_id
AGORA_APP_CERTIFICATE=your_agora_certificate
EMAIL_USER=your_email
EMAIL_PASS=your_email_password
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...} # Optional for push notifications
```

### Mobile App Configuration
Update `mobile_app/lib/core/config/app_config.dart`:
```dart
static const String baseUrl = 'http://your-server:5000';
static const String agoraAppId = 'your_agora_app_id';
```

## 🛠️ Tech Stack

### Mobile App
- Flutter & Dart
- Provider (State Management)
- Socket.IO Client
- Agora SDK (Video/Voice)
- Go Router (Navigation)

### Admin Dashboard
- React.js
- Material-UI
- Axios
- React Router

### Backend
- Node.js & Express
- MongoDB & Mongoose
- Socket.IO
- JWT Authentication
- Agora RTC
- Nodemailer

## 📱 Mobile App Features Detail

### Authentication
- Email/password registration
- Email verification with OTP
- Login with JWT tokens
- Password reset
- Role-based access (Student/Tutor)

### Booking System
- Browse available tutors
- Filter by subject, price, rating
- View tutor availability slots
- Request bookings
- Confirm/reject bookings (Tutors)
- Cancel bookings
- View booking history

### Chat System
- Real-time messaging
- Voice message recording
- File attachments
- Typing indicators
- Read receipts
- Message history

### Call System
- Voice calls
- Video calls
- Call history
- Incoming call notifications
- Call duration tracking

## 🔐 Security

- JWT-based authentication
- Password hashing with bcrypt
- Input validation
- CORS configuration
- Rate limiting
- Secure file uploads

## 📄 License

This project is proprietary and confidential.

## 👥 Support

For support, contact the development team.
