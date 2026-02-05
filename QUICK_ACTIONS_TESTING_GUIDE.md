# 🧪 Quick Actions Testing Guide

This guide provides step-by-step instructions for testing all three quick action features implemented in the tutor and student profile screens.

---

## 📋 Prerequisites

Before testing, ensure:
1. ✅ Backend server is running (`npm start` in server directory)
2. ✅ MongoDB is connected
3. ✅ Mobile app is built and running
4. ✅ You have test accounts (both tutor and student)

---

## 🎯 Test 1: View Analytics (Tutor Only)

### Steps:
1. **Login as Tutor**
   - Use a tutor account with some bookings/reviews

2. **Navigate to Profile**
   - Go to Tutor Dashboard
   - Tap on "Profile" tab

3. **Click View Analytics**
   - Scroll to "Quick Actions" section
   - Tap "View Analytics"

4. **Verify Navigation**
   - Should navigate to Earnings screen
   - Screen should show three tabs: Overview, Transactions, Analytics

5. **Check Analytics Tab**
   - Tap on "Analytics" tab
   - Should see:
     - Average Rating (from actual reviews)
     - Response Rate (confirmed/total requests)
     - Completion Rate (completed/confirmed)
     - Repeat Student Rate
     - Subject Performance chart
     - Monthly Trends chart

### Expected Results:
- ✅ Navigation works smoothly
- ✅ Analytics tab displays real data
- ✅ All metrics are calculated correctly
- ✅ Charts render properly
- ✅ No errors in console

### Test Data:
If no data shows:
- Create some test bookings
- Add some reviews
- Complete some sessions
- Then check analytics again

---

## 🔔 Test 2: Notification Preferences

### Steps:
1. **Login as Tutor or Student**
   - Works for both user types

2. **Navigate to Profile**
   - Go to Dashboard
   - Tap on "Profile" tab

3. **Open Notification Preferences**
   - Scroll to "Account Settings" section
   - Tap "Notifications"

4. **Verify Screen Loads**
   - Should see Notification Preferences screen
   - Two sections: General Settings and Notification Types
   - All toggles should be visible

5. **Test General Settings**
   - Toggle "Email Notifications" off
   - Toggle "Push Notifications" off
   - Verify switches respond

6. **Test Notification Types**
   - Toggle "Message Notifications" off
   - Toggle "Promotional Notifications" on
   - Toggle other preferences as desired

7. **Save Preferences**
   - Tap "Save" button in app bar
   - Should see success message
   - Loading indicator should show briefly

8. **Verify Persistence**
   - Close the screen
   - Reopen Notification Preferences
   - All toggles should be in the same state as saved

9. **Test Backend**
   - Check MongoDB to verify preferences are saved
   - Or use the test script: `node server/scripts/testNotificationPreferences.js`

### Expected Results:
- ✅ Screen loads without errors
- ✅ All toggles work smoothly
- ✅ Save button shows loading state
- ✅ Success message appears
- ✅ Preferences persist after closing
- ✅ Dark mode works correctly
- ✅ Backend saves preferences to database

### Edge Cases to Test:
- Toggle all preferences off
- Toggle all preferences on
- Save without making changes
- Close without saving (changes should not persist)

---

## 🔒 Test 3: Change Password

### Steps:
1. **Login as Tutor or Student**
   - Works for both user types
   - Remember your current password!

2. **Navigate to Profile**
   - Go to Dashboard
   - Tap on "Profile" tab

3. **Open Change Password Dialog**
   - Scroll to "Account Settings" section
   - Tap "Change Password"

4. **Verify Dialog Appears**
   - Should see modal dialog
   - Three password fields visible
   - Password requirements shown
   - Cancel and Change Password buttons

5. **Test Validation - Empty Fields**
   - Leave all fields empty
   - Tap "Change Password"
   - Should see validation errors

6. **Test Validation - Wrong Current Password**
   - Enter incorrect current password
   - Enter valid new password
   - Confirm new password
   - Tap "Change Password"
   - Should see error: "Current password is incorrect"

7. **Test Validation - Weak Password**
   - Enter correct current password
   - Enter "12345" as new password (< 6 chars)
   - Tap "Change Password"
   - Should see error: "Password must be at least 6 characters"

8. **Test Validation - Mismatched Confirmation**
   - Enter correct current password
   - Enter "newPassword123" as new password
   - Enter "differentPassword" as confirmation
   - Tap "Change Password"
   - Should see error: "Passwords do not match"

9. **Test Validation - Same as Current**
   - Enter current password in all three fields
   - Tap "Change Password"
   - Should see error: "New password must be different from current password"

10. **Test Successful Change**
    - Enter correct current password
    - Enter "newPassword123" as new password
    - Enter "newPassword123" as confirmation
    - Tap "Change Password"
    - Should see success message
    - Dialog should close

11. **Verify Password Changed**
    - Logout
    - Try to login with old password (should fail)
    - Login with new password (should succeed)

12. **Change Back to Original**
    - Repeat steps to change password back to original
    - This ensures you can continue testing

### Expected Results:
- ✅ Dialog opens smoothly
- ✅ All validation rules work correctly
- ✅ Password visibility toggles work
- ✅ Loading state shows during API call
- ✅ Success message appears
- ✅ Dialog closes after success
- ✅ Password actually changes in database
- ✅ Can login with new password
- ✅ Cannot login with old password
- ✅ Dark mode works correctly

### Edge Cases to Test:
- Very long password (should work)
- Password with special characters (should work)
- Cancel button (should close without changes)
- Close dialog with X button (should close without changes)
- Network error during save (should show error)

---

## 🧪 Backend Testing Scripts

### Test Notification Preferences API
```bash
# 1. Get a JWT token by logging in
# 2. Edit server/scripts/testNotificationPreferences.js
# 3. Replace JWT_TOKEN with your token
# 4. Run the script
node server/scripts/testNotificationPreferences.js
```

### Test Change Password API
```bash
# 1. Get a JWT token by logging in
# 2. Edit server/scripts/testChangePassword.js
# 3. Replace JWT_TOKEN and CURRENT_PASSWORD
# 4. Run the script (use test account!)
node server/scripts/testChangePassword.js
```

---

## 🐛 Common Issues & Solutions

### Issue: "Coming soon" message still shows
**Solution**: Make sure you've rebuilt the app after code changes
```bash
cd mobile_app
flutter clean
flutter pub get
flutter run
```

### Issue: Notification preferences don't save
**Solution**: 
- Check server logs for errors
- Verify MongoDB connection
- Check JWT token is valid
- Verify user exists in database

### Issue: Change password fails with "User not found"
**Solution**:
- JWT token might be expired
- Logout and login again
- Check server logs

### Issue: Analytics shows no data
**Solution**:
- Create test bookings for the tutor
- Add some reviews
- Complete some sessions
- Analytics needs real data to display

### Issue: Dark mode looks broken
**Solution**:
- Check theme provider is working
- Verify all color values are defined
- Restart app

---

## ✅ Testing Checklist

### View Analytics (Tutor)
- [ ] Navigation works
- [ ] Analytics tab loads
- [ ] Real data displays
- [ ] Charts render correctly
- [ ] No console errors

### Notification Preferences (Both)
- [ ] Screen loads
- [ ] All toggles work
- [ ] Save functionality works
- [ ] Preferences persist
- [ ] Backend saves correctly
- [ ] Dark mode works

### Change Password (Both)
- [ ] Dialog opens
- [ ] All validations work
- [ ] Password visibility toggles work
- [ ] Successful change works
- [ ] Can login with new password
- [ ] Cannot login with old password
- [ ] Dark mode works

---

## 📊 Test Results Template

Use this template to document your test results:

```
Date: ___________
Tester: ___________
App Version: ___________

View Analytics:
- Navigation: ✅ / ❌
- Data Display: ✅ / ❌
- Charts: ✅ / ❌
- Notes: ___________

Notification Preferences:
- Screen Load: ✅ / ❌
- Toggle Functionality: ✅ / ❌
- Save Functionality: ✅ / ❌
- Persistence: ✅ / ❌
- Notes: ___________

Change Password:
- Dialog Display: ✅ / ❌
- Validation: ✅ / ❌
- Password Change: ✅ / ❌
- Login Verification: ✅ / ❌
- Notes: ___________

Overall Status: ✅ PASS / ❌ FAIL
```

---

## 🎯 Success Criteria

All tests pass when:
1. ✅ All features work without errors
2. ✅ Data persists correctly
3. ✅ Validation works as expected
4. ✅ UI is responsive and smooth
5. ✅ Dark mode works correctly
6. ✅ Backend APIs respond correctly
7. ✅ No console errors or warnings
8. ✅ User experience is intuitive

---

## 📝 Notes

- Always use test accounts for testing password changes
- Document any bugs found during testing
- Take screenshots of any UI issues
- Check server logs for backend errors
- Test on both Android and iOS if possible
- Test with different screen sizes
- Test with slow network conditions

---

## 🚀 Next Steps After Testing

If all tests pass:
1. ✅ Mark features as complete
2. ✅ Update documentation
3. ✅ Deploy to production
4. ✅ Monitor for issues

If tests fail:
1. ❌ Document the failures
2. ❌ Create bug tickets
3. ❌ Fix issues
4. ❌ Retest
