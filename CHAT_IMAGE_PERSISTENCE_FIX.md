# ❌ Chat Images Disappear After Logout - SOLUTION

## Problem

Images sent in chat disappear after logout/re-login because:

1. **Render Free Tier** uses **ephemeral file system**
2. Files uploaded to `/uploads/chat/` are stored on server's disk
3. When server restarts/sleeps, the disk is wiped clean
4. All uploaded images are lost permanently

## Why This Happens on Render

Render free tier containers are **stateless**:
- File system resets on every deploy
- File system resets when server sleeps (after 15 min inactivity)
- File system resets on server restart
- `/uploads/` folder is NOT persistent

## Solution: Use Cloudinary (Cloud Storage)

Instead of saving files to server disk, save them to **Cloudinary** (permanent cloud storage).

### Benefits:
- ✅ Images never disappear
- ✅ Free tier: 25GB storage + 25GB bandwidth/month
- ✅ Automatic image optimization
- ✅ Fast CDN delivery
- ✅ No credit card required for free tier

## Implementation Steps

### 1. Create Cloudinary Account

1. Go to: https://cloudinary.com/users/register/free
2. Sign up (free, no credit card needed)
3. After signup, go to Dashboard
4. Copy these credentials:
   - **Cloud Name**
   - **API Key**
   - **API Secret**

### 2. Install Cloudinary Package

```bash
cd server
npm install cloudinary multer-storage-cloudinary
```

### 3. Update server/.env

Add Cloudinary credentials:

```env
# Cloudinary Configuration (for file uploads)
CLOUDINARY_CLOUD_NAME=your_cloud_name_here
CLOUDINARY_API_KEY=your_api_key_here
CLOUDINARY_API_SECRET=your_api_secret_here
```

### 4. Create Cloudinary Config File

Create `server/config/cloudinary.js`:

```javascript
const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Create storage for chat attachments
const chatStorage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'tutor-app/chat',
    allowed_formats: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx'],
    resource_type: 'auto', // Supports images, videos, and raw files
  },
});

// Create storage for profile pictures
const profileStorage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'tutor-app/profiles',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [{ width: 500, height: 500, crop: 'limit' }],
  },
});

module.exports = {
  cloudinary,
  chatStorage,
  profileStorage
};
```

### 5. Update Chat Routes

Update `server/routes/chat.js` to use Cloudinary:

```javascript
const multer = require('multer');
const { chatStorage } = require('../config/cloudinary');

// Replace local storage with Cloudinary
const upload = multer({ storage: chatStorage });

// Upload endpoint
router.post('/upload', auth, upload.single('file'), chatController.uploadAttachment);
```

### 6. Update Chat Controller

Update `server/controllers/chatController.js`:

```javascript
// Upload attachment
exports.uploadAttachment = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    // Cloudinary automatically uploads and returns URL
    const fileUrl = req.file.path; // This is the Cloudinary URL
    
    // Determine file type
    let fileType = 'document';
    if (req.file.mimetype.startsWith('audio/')) {
      fileType = 'audio';
    } else if (req.file.mimetype.startsWith('image/')) {
      fileType = 'image';
    } else if (req.file.mimetype.startsWith('video/')) {
      fileType = 'video';
    }

    res.json({
      success: true,
      data: {
        name: req.file.originalname,
        url: fileUrl, // Full Cloudinary URL
        type: fileType,
        size: req.file.size,
        mimeType: req.file.mimetype
      }
    });

  } catch (error) {
    console.error('Upload attachment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload attachment',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};
```

### 7. Update Render Environment Variables

On Render dashboard, add:
```
CLOUDINARY_CLOUD_NAME = your_cloud_name
CLOUDINARY_API_KEY = your_api_key
CLOUDINARY_API_SECRET = your_api_secret
```

### 8. Deploy to Render

```bash
git add .
git commit -m "Add Cloudinary for persistent file storage"
git push origin main
```

Render will auto-deploy (3-5 minutes).

## After Implementation

### What Changes:
- ✅ Images upload to Cloudinary (not server disk)
- ✅ Images get permanent URLs like: `https://res.cloudinary.com/your-cloud/image/upload/v123/tutor-app/chat/abc123.jpg`
- ✅ Images never disappear
- ✅ Works after logout/login
- ✅ Works after server restart
- ✅ Faster image loading (CDN)

### Mobile App:
- No changes needed!
- App already handles full URLs
- Images will just work permanently

## Testing

1. Send an image in chat
2. Logout and login again
3. Image should still be there! ✅
4. Restart server - image still there! ✅

## Cloudinary Free Tier Limits

- **Storage**: 25 GB
- **Bandwidth**: 25 GB/month
- **Transformations**: 25,000/month
- **Perfect for**: Testing and small apps
- **Upgrade**: Only when you exceed limits

## Alternative: Keep Current Setup (Not Recommended)

If you don't want to use Cloudinary, you can:
1. Upgrade to Render paid plan ($7/month) with persistent disk
2. Use a separate file storage service
3. Accept that images will disappear (not good for users!)

## Recommendation

✅ **Use Cloudinary** - It's free, easy, and solves the problem permanently.

The current setup (local file storage) will NEVER work reliably on Render free tier because the file system is ephemeral by design.
