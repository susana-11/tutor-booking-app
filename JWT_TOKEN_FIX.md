# ❌ Invalid Token Error - Profile Visibility & Picture Upload

## Problem

Getting `401 - Invalid token` errors when:
- Toggling profile visibility
- Uploading profile picture

```
❌ ERROR: 401 https://tutor-app-backend-wtru.onrender.com/api/tutors/profile/visibility
📥 ERROR DATA: {success: false, message: Invalid token.}
```

## Root Cause

You updated the `JWT_SECRET` in `.env` file. This invalidated all existing JWT tokens because:

1. Old tokens were signed with old JWT_SECRET
2. Server now uses new JWT_SECRET to verify tokens
3. Old tokens fail verification → "Invalid token" error

## Solution

### Quick Fix: Logout and Login Again

**On Mobile App:**
1. Tap profile/menu
2. Tap "Logout"
3. Login again with same credentials
4. New token will be generated with new JWT_SECRET
5. Everything will work! ✅

### Why This Works:
- Login generates a NEW token signed with NEW JWT_SECRET
- Server can verify the new token
- Profile visibility toggle works
- Profile picture upload works

## For Render Deployment

When you update JWT_SECRET on Render:

1. **Update environment variable** on Render dashboard
2. **All users must logout/login** to get new tokens
3. Or wait 7 days for tokens to expire naturally

## Important Notes

### JWT_SECRET Changes:
- ✅ Makes authentication more secure
- ❌ Invalidates all existing tokens
- ⚠️ All users must re-login

### Best Practice:
- Only change JWT_SECRET when necessary
- Notify users to re-login after change
- Or implement token refresh mechanism

## Current JWT_SECRET

```env
JWT_SECRET=tutorapp_2026_secure_jwt_secret_key_0ad4c02139aa48b28e813b4e9676ea0a_production_ready_v1
```

This is a strong, secure secret. Keep it!

## Testing After Re-login

After logout/login:
- [ ] Profile visibility toggle works
- [ ] Profile picture upload works
- [ ] All API calls work
- [ ] No more "Invalid token" errors

## Summary

**The fix is simple**: Logout and login again on the mobile app. The new JWT_SECRET is more secure, but requires all users to get new tokens.

**Status**: ✅ Not a bug - Expected behavior after JWT_SECRET change
