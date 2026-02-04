# 🔐 TEST ACCOUNTS - LOGIN CREDENTIALS

## 📱 STUDENT ACCOUNT

```
Email:    etsebruk@example.com
Password: 123abc
Name:     Etsebruk Amanuel
Role:     Student
```

**Use this to:**
- Search for tutors
- Book sessions
- Make payments
- Join video sessions
- Rate tutors
- Send messages

---

## 👨‍🏫 TUTOR ACCOUNT

```
Email:    bubuam13@gmail.com
Password: 123abc
Name:     Hindekie Amanuel
Role:     Tutor
Subject:  Economics
Rate:     500 ETB/hour
```

**Use this to:**
- Accept bookings
- Start sessions
- Receive payments
- Manage schedule
- Reply to messages
- View earnings

---

## 🎯 QUICK LOGIN GUIDE

### For Student Testing:
1. Open mobile app
2. Click "Login"
3. Enter: `etsebruk@example.com`
4. Password: `123abc`
5. Click "Login"

### For Tutor Testing:
1. Open mobile app
2. Click "Login"
3. Enter: `bubuam13@gmail.com`
4. Password: `123abc`
5. Click "Login"

---

## 🧪 TWO-DEVICE TESTING

### Device 1 (Student):
```
Login: etsebruk@example.com
Password: 123abc
```

### Device 2 (Tutor):
```
Login: bubuam13@gmail.com
Password: 123abc
```

**Test Flow:**
1. Student searches for tutor
2. Student books session
3. Student makes payment
4. Tutor accepts booking
5. Both join video session
6. Test video/audio controls
7. End session
8. Rate each other

---

## 📊 ACCOUNT DETAILS

### Student Profile:
- **Name:** Etsebruk Amanuel
- **Phone:** 0911223344
- **Grade:** 12
- **School:** Test High School
- **Goals:** Improve Economics, Prepare for university
- **Status:** ✅ Email verified, Profile complete

### Tutor Profile:
- **Name:** Hindekie Amanuel
- **Phone:** 0923394163
- **Subject:** Economics
- **Experience:** 5 years
- **Education:** Bachelor in Economics (AAU, 2018)
- **Rate:** 500 ETB/hour
- **Rating:** 4.8 ⭐ (15 reviews)
- **Sessions:** 50 completed
- **Status:** ✅ Verified, Accepting bookings

---

## 🔄 CREATE MORE TEST USERS

If you need more test accounts, run:

```bash
cd server
node scripts/createCloudTestUsers.js
```

Or create manually in the app:
1. Click "Register"
2. Fill in details
3. Verify email (check console logs)
4. Complete profile

---

## 🚨 IMPORTANT NOTES

### Password:
- All test accounts use: `123abc`
- Change in production!

### Email Verification:
- Test accounts are pre-verified
- New accounts need email verification
- Check server console for OTP codes

### Profiles:
- Both accounts have complete profiles
- Ready to use immediately
- No additional setup needed

---

## 💡 TESTING SCENARIOS

### Scenario 1: Book a Session
```
1. Login as student (etsebruk@example.com)
2. Search for tutors
3. Find Hindekie (Economics tutor)
4. View profile
5. Book a session
6. Make payment
```

### Scenario 2: Accept Booking
```
1. Login as tutor (bubuam13@gmail.com)
2. Go to Bookings
3. See pending booking
4. Accept booking
5. Wait for session time
```

### Scenario 3: Video Session
```
1. Student starts session
2. Tutor joins session
3. Both see video/audio
4. Test controls (mute, camera, etc.)
5. End session
6. Add notes
7. Rate session
```

### Scenario 4: Chat
```
1. Student messages tutor
2. Tutor replies
3. Send text, images, voice
4. Test reply/forward
5. Test attachments
```

---

## 🔧 TROUBLESHOOTING

### Can't Login?
- Check email is exactly: `etsebruk@example.com` or `bubuam13@gmail.com`
- Password is: `123abc` (lowercase)
- Make sure server is running
- Check API_BASE_URL in app

### Account Not Found?
Run the creation script:
```bash
cd server
node scripts/createCloudTestUsers.js
```

### Need to Reset Password?
```bash
cd server
node scripts/resetPassword.js
```

---

## 📝 QUICK REFERENCE

| Account | Email | Password | Role |
|---------|-------|----------|------|
| **Student** | etsebruk@example.com | 123abc | Student |
| **Tutor** | bubuam13@gmail.com | 123abc | Tutor |

**Both accounts are ready to use!** ✅

---

## 🎉 READY TO TEST!

Use these accounts to test:
- ✅ Login/Registration
- ✅ Profile management
- ✅ Tutor search
- ✅ Booking flow
- ✅ Payment system
- ✅ Video sessions
- ✅ Chat/messaging
- ✅ Rating/reviews
- ✅ Notifications

**Start testing now!** 🚀
