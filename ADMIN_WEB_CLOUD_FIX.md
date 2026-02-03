# 🔧 Admin Web App - Cloud Server Fix

## Problem Fixed

The admin web app was trying to connect to `http://localhost:5000` but your local server isn't running. 

## Solution Applied

Updated `admin-web/package.json` proxy setting to use your Render cloud server:

```json
"proxy": "https://tutor-app-backend-wtru.onrender.com"
```

## Next Steps

1. **Stop the current admin web app** (press Ctrl+C in the terminal)

2. **Restart the admin web app**:
```bash
cd admin-web
npm start
```

3. **Open in browser**: http://localhost:3000

4. **Login with admin credentials**:
   - You need to create an admin user first (see below)

---

## Create Admin User

Before you can login to the admin panel, you need to create an admin user in your cloud database.

### Option 1: Run Script Locally (Connects to Cloud DB)

```bash
cd server
node scripts/createAdmin.js
```

This will create an admin user with:
- **Email**: admin@tutorbooking.com
- **Password**: admin123456

### Option 2: Create Admin Manually via MongoDB Atlas

1. Go to: https://cloud.mongodb.com
2. Click **"Browse Collections"**
3. Find the `users` collection
4. Click **"Insert Document"**
5. Add this document:

```json
{
  "name": "Admin User",
  "email": "admin@tutorbooking.com",
  "password": "$2a$10$YourHashedPasswordHere",
  "role": "admin",
  "isEmailVerified": true,
  "createdAt": { "$date": "2026-02-03T00:00:00.000Z" },
  "updatedAt": { "$date": "2026-02-03T00:00:00.000Z" }
}
```

Note: For the password, you'll need to hash it. Use the script method instead.

---

## After Creating Admin User

1. Open admin web app: http://localhost:3000
2. Login with:
   - **Email**: admin@tutorbooking.com
   - **Password**: admin123456
3. You should see the admin dashboard

---

## Admin Dashboard Features

Once logged in, you can:

- ✅ View all users (students & tutors)
- ✅ Approve/reject tutor applications
- ✅ Manage bookings
- ✅ View payments & transactions
- ✅ Handle disputes
- ✅ Manage subjects
- ✅ View analytics & statistics
- ✅ System settings

---

## Important Notes

### First Request May Be Slow
- Render free tier sleeps after 15 minutes
- First login may take 30-60 seconds to wake up the server
- Subsequent requests will be fast

### CORS Configuration
The server is already configured to allow requests from `http://localhost:3000` for the admin panel.

### Production Deployment
To deploy the admin web app to production:

1. Build the app:
```bash
cd admin-web
npm run build
```

2. Deploy the `build` folder to:
   - Netlify
   - Vercel
   - GitHub Pages
   - Or serve from your Render server

---

## Troubleshooting

### "Proxy error: ECONNREFUSED"
- This means the server isn't responding
- Wait 60 seconds for Render server to wake up
- Check server status: https://tutor-app-backend-wtru.onrender.com/api/health

### "Invalid credentials"
- Make sure you created the admin user
- Check email/password are correct
- Verify user has `role: "admin"` in database

### "Not authorized"
- User must have `role: "admin"`
- Check the user document in MongoDB

---

## Current Status

✅ Admin web proxy updated to cloud server  
⏳ Need to create admin user  
⏳ Need to restart admin web app  

**Next**: Stop current process (Ctrl+C) and run `npm start` again
