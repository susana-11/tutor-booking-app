# 🚨 URGENT: Update Render Environment Variables

## What You Need To Do NOW

Your code has been pushed to GitHub, but Render needs the Cloudinary credentials to work properly.

## Step-by-Step Instructions

### 1. Open Render Dashboard
Go to: https://dashboard.render.com

### 2. Select Your Service
- Click on your backend service (tutor-app-backend or similar)

### 3. Go to Environment Tab
- Click "Environment" in the left sidebar

### 4. Add These 3 Variables
Click "Add Environment Variable" for each:

**Variable 1:**
```
Key: CLOUDINARY_CLOUD_NAME
Value: dltkiz8xe
```

**Variable 2:**
```
Key: CLOUDINARY_API_KEY
Value: 665833722728212
```

**Variable 3:**
```
Key: CLOUDINARY_API_SECRET
Value: fgTUK_gaGprufE-V1kP80EkVs2o
```

### 5. Save Changes
- Click "Save Changes" button at the bottom
- Render will automatically redeploy (takes 3-5 minutes)

### 6. Wait for Deployment
- You'll see "Deploying..." status
- Wait until it shows "Live" status
- Check the logs to confirm no errors

## How to Check Logs

1. In Render dashboard, click "Logs" tab
2. Look for these success messages:
   ```
   ✅ MongoDB connected successfully
   ✅ Server running on port 5000
   ```
3. Should NOT see any Cloudinary errors

## After Deployment Complete

### Test Profile Picture Upload:
1. Open mobile app
2. Logout and login again (to refresh token)
3. Go to Profile screen
4. Tap profile picture icon
5. Select image from gallery
6. Should upload successfully ✅
7. Logout and login again
8. Profile picture should still be there ✅

### Test Chat Image Upload:
1. Open any chat conversation
2. Tap "+" button
3. Select "Take Photo" or "Choose from Gallery"
4. Send image
5. Image should appear in chat ✅
6. Logout and login again
7. Image should still be visible ✅

## Troubleshooting

### If Upload Still Fails:
1. Check Render logs for errors
2. Verify all 3 environment variables are set correctly
3. Make sure deployment completed successfully
4. Try restarting the service in Render

### If Images Disappear:
1. Check if Cloudinary credentials are correct
2. Verify the service redeployed after adding variables
3. Check Cloudinary dashboard to see if images are being uploaded

## Important Notes

⚠️ **Without these environment variables, uploads will fail!**  
⚠️ **You must add them to Render, not just local `.env` file**  
⚠️ **Render auto-deploys when you save environment variables**  
⚠️ **Wait for deployment to complete before testing**

---

**Current Status**: Code pushed to GitHub ✅  
**Your Action Required**: Add environment variables to Render 🚨  
**Estimated Time**: 5 minutes to add + 3-5 minutes deployment
