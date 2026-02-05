# 🚀 Quick Actions - Quick Reference

## 📍 Location
**Tutor Profile**: Dashboard → Profile Tab → Scroll to "Quick Actions" or "Account Settings"
**Student Profile**: Dashboard → Profile Tab → Scroll to "Account Settings"

---

## 1️⃣ View Analytics (Tutor Only)

**Button**: "View Analytics" under Quick Actions
**Action**: Navigates to Earnings screen → Analytics tab
**Shows**: 
- Average Rating
- Response Rate
- Completion Rate  
- Repeat Student Rate
- Subject Performance
- Monthly Trends

---

## 2️⃣ Notification Preferences

**Button**: "Notifications" under Account Settings
**Action**: Opens Notification Preferences screen

**Settings Available**:
- Email Notifications (on/off)
- Push Notifications (on/off)
- Booking Notifications (on/off)
- Message Notifications (on/off)
- Review Notifications (on/off)
- Payment Notifications (on/off)
- Reminder Notifications (on/off)
- Promotional Notifications (on/off)

**Save**: Tap "Save" button in app bar

---

## 3️⃣ Change Password

**Button**: "Change Password" under Account Settings
**Action**: Opens Change Password dialog

**Fields**:
1. Current Password
2. New Password (min 6 chars)
3. Confirm New Password

**Validation**:
- Current password must be correct
- New password min 6 characters
- New password must differ from current
- Confirmation must match new password

**Submit**: Tap "Change Password" button

---

## 🔗 API Endpoints

```
GET  /api/users/notification-preferences
PUT  /api/users/notification-preferences
PUT  /api/auth/change-password
```

---

## 📱 Works For
- ✅ Tutors (all 3 features)
- ✅ Students (notifications + password)

---

## 🎨 Features
- ✅ Dark mode support
- ✅ Real data from database
- ✅ Form validation
- ✅ Loading states
- ✅ Success/error messages
