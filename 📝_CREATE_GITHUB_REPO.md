# 📝 How to Create GitHub Repository

## 🎯 You Need to Do This FIRST!

Before pushing code, you must create the repository on GitHub.

---

## Step-by-Step Guide

### Step 1: Go to GitHub

Open browser and visit: **https://github.com**

**If you don't have account:**
- Click "Sign up"
- Create free account
- Verify email

**If you have account:**
- Click "Sign in"
- Enter credentials

---

### Step 2: Create New Repository

1. **Click the "+" icon** (top right corner of GitHub page)

2. **Select "New repository"**

3. **Fill in the form:**

   ```
   Repository name: tutor-booking-app
   
   Description: Tutor booking platform with Flutter mobile app
   
   Visibility: 
   ○ Public (anyone can see)
   ● Private (only you can see) ← RECOMMENDED
   
   Initialize this repository:
   ☐ Add a README file ← LEAVE UNCHECKED!
   ☐ Add .gitignore ← LEAVE UNCHECKED!
   ☐ Choose a license ← LEAVE UNCHECKED!
   ```

4. **Click "Create repository"** (green button at bottom)

---

### Step 3: Copy Your Repository URL

After creating, GitHub shows a page with commands.

**Your repository URL will be:**
```
https://github.com/YOUR_USERNAME/tutor-booking-app.git
```

**Example:**
- If your username is `etsebruk123`
- URL is: `https://github.com/etsebruk123/tutor-booking-app.git`

**Copy this URL!** You'll need it in the next step.

---

### Step 4: Push Your Code

**Option A: Use the Helper Script (Easiest)**

1. Double-click: `push-to-github.bat`
2. Enter your GitHub username when asked
3. Confirm
4. Done!

**Option B: Manual Commands**

Replace `YOUR_USERNAME` with your actual GitHub username:

```bash
git remote add origin https://github.com/YOUR_USERNAME/tutor-booking-app.git
git branch -M main
git push -u origin main
```

**Example with username `etsebruk123`:**
```bash
git remote add origin https://github.com/etsebruk123/tutor-booking-app.git
git branch -M main
git push -u origin main
```

---

### Step 5: Verify

After pushing, refresh your GitHub repository page.

You should see:
- ✅ All your files
- ✅ 325 files
- ✅ Folders: server, mobile_app, admin-web
- ✅ README.md and other files

---

## 🔐 Authentication

When you push, GitHub may ask for credentials:

### Option 1: Personal Access Token (Recommended)

1. **Generate token:**
   - GitHub → Settings → Developer settings
   - Personal access tokens → Tokens (classic)
   - Generate new token
   - Select scopes: `repo` (all)
   - Copy token (save it somewhere!)

2. **When pushing:**
   - Username: your GitHub username
   - Password: paste the token (NOT your GitHub password)

### Option 2: GitHub CLI

```bash
# Install GitHub CLI first
# Then authenticate:
gh auth login
```

### Option 3: SSH Key

If you have SSH key set up, use SSH URL instead:
```
git@github.com:YOUR_USERNAME/tutor-booking-app.git
```

---

## ❌ Common Errors

### "Repository not found"

**Cause:** Repository doesn't exist on GitHub

**Fix:**
1. Go to GitHub
2. Make sure you created the repository
3. Check the repository name is exactly: `tutor-booking-app`
4. Check your username is correct

### "Permission denied"

**Cause:** Not authenticated

**Fix:**
1. Use Personal Access Token (see above)
2. Or use GitHub CLI: `gh auth login`
3. Or set up SSH key

### "Remote origin already exists"

**Cause:** You already added a remote

**Fix:**
```bash
git remote remove origin
# Then add again with correct URL
git remote add origin https://github.com/YOUR_USERNAME/tutor-booking-app.git
```

---

## ✅ Success!

After successful push, you should see:

```
Enumerating objects: 325, done.
Counting objects: 100% (325/325), done.
Delta compression using up to 8 threads
Compressing objects: 100% (300/300), done.
Writing objects: 100% (325/325), 1.5 MiB | 500 KiB/s, done.
Total 325 (delta 150), reused 0 (delta 0)
To https://github.com/YOUR_USERNAME/tutor-booking-app.git
 * [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

---

## 🚀 Next Step

After code is on GitHub:

**Deploy to Render.com!**

See: `🚀_RENDER_DEPLOYMENT_STEPS.md`

---

## 📞 Quick Reference

**GitHub:** https://github.com
**Create Repo:** Click "+" → "New repository"
**Repo Name:** `tutor-booking-app`
**Visibility:** Private (recommended)
**Initialize:** Leave all unchecked

**Helper Script:** `push-to-github.bat`
**Manual Command:** `git remote add origin https://github.com/YOUR_USERNAME/tutor-booking-app.git`

---

## 🆘 Need Help?

1. Make sure you're logged into GitHub
2. Make sure repository is created
3. Use correct username (check GitHub profile)
4. Use Personal Access Token for password
5. Try the helper script: `push-to-github.bat`

Good luck! 🚀
