# 📋 Deployment Checklist

## ✅ Pre-Deployment (DONE)

- [x] Git repository initialized
- [x] All code committed (325 files)
- [x] .gitignore configured
- [x] Server package.json ready
- [x] Environment variables documented
- [x] Deployment guides created

---

## 🚀 Deployment Steps

### Phase 1: GitHub (5 minutes)

- [ ] Go to https://github.com
- [ ] Create new repository: `tutor-booking-app`
- [ ] Keep it Private
- [ ] DO NOT initialize with README
- [ ] Copy the repository URL
- [ ] Run: `git remote add origin <URL>`
- [ ] Run: `git branch -M main`
- [ ] Run: `git push -u origin main`
- [ ] Verify code is on GitHub

**Commands:** See `GITHUB_PUSH_COMMANDS.txt`

---

### Phase 2: Render.com (10 minutes)

- [ ] Go to https://render.com
- [ ] Sign up with GitHub
- [ ] Authorize Render to access GitHub
- [ ] Click "New +" → "Web Service"
- [ ] Select `tutor-booking-app` repository
- [ ] Click "Connect"

**Configuration:**
- [ ] Name: `tutor-app-backend`
- [ ] Region: Europe/Frankfurt or Singapore
- [ ] Branch: `main`
- [ ] Root Directory: `server`
- [ ] Environment: `Node`
- [ ] Build Command: `npm install`
- [ ] Start Command: `npm start`
- [ ] Instance Type: `Free`

**Environment Variables:**
- [ ] MONGODB_URI
- [ ] JWT_SECRET
- [ ] JWT_EXPIRE
- [ ] NODE_ENV
- [ ] PORT
- [ ] EMAIL_HOST
- [ ] EMAIL_PORT
- [ ] EMAIL_USER
- [ ] EMAIL_PASS
- [ ] TWILIO_ACCOUNT_SID
- [ ] TWILIO_AUTH_TOKEN
- [ ] TWILIO_PHONE_NUMBER
- [ ] AGORA_APP_ID
- [ ] AGORA_APP_CERTIFICATE
- [ ] CHAPA_SECRET_KEY
- [ ] CHAPA_PUBLIC_KEY
- [ ] CHAPA_BASE_URL
- [ ] PLATFORM_FEE_PERCENTAGE
- [ ] MIN_WITHDRAWAL_AMOUNT

**Deploy:**
- [ ] Click "Create Web Service"
- [ ] Wait for deployment (5-10 min)
- [ ] Status shows "Live" ✅
- [ ] Copy your Render URL

**Update Callbacks:**
- [ ] Add CHAPA_CALLBACK_URL
- [ ] Add CHAPA_RETURN_URL
- [ ] Add FRONTEND_URL
- [ ] Save changes (auto-redeploys)

**Guide:** See `🚀_RENDER_DEPLOYMENT_STEPS.md`

---

### Phase 3: Test Deployment (2 minutes)

- [ ] Open browser
- [ ] Visit: `https://tutor-app-backend.onrender.com`
- [ ] Should see: `{"message":"Route not found"}`
- [ ] Visit: `https://tutor-app-backend.onrender.com/api/subjects`
- [ ] Should see: List of subjects
- [ ] Check Render logs for errors

---

### Phase 4: Update Mobile App (5 minutes)

**Update Config:**
- [ ] Open `mobile_app/lib/core/config/app_config.dart`
- [ ] Change `_baseUrlDev` to your Render URL
- [ ] Change `_baseUrlProd` to your Render URL
- [ ] Save file

**Rebuild:**
- [ ] Run: `cd mobile_app`
- [ ] Run: `flutter clean`
- [ ] Run: `flutter build apk --release`
- [ ] Wait for build to complete
- [ ] Find APK: `build/app/outputs/flutter-apk/app-release.apk`

**Install:**
- [ ] Transfer APK to Phone 1
- [ ] Transfer APK to Phone 2
- [ ] Install on both phones
- [ ] Uninstall old version first if needed

---

### Phase 5: Test Everything (10 minutes)

**Phone 1 (Student):**
- [ ] Open app
- [ ] Login works
- [ ] Search tutors works
- [ ] View tutor profile works
- [ ] Book session works
- [ ] Payment redirect works
- [ ] Payment completes

**Phone 2 (Tutor):**
- [ ] Open app
- [ ] Login works
- [ ] See booking request
- [ ] Accept booking works
- [ ] Dashboard shows booking

**Both Phones:**
- [ ] Start session works
- [ ] Video call connects
- [ ] Audio works
- [ ] Video works
- [ ] Chat works
- [ ] End session works
- [ ] Rating screen appears
- [ ] Submit rating works

---

## 🎯 Success Criteria

✅ **Deployment Successful:**
- Server shows "Live" on Render
- Browser test returns JSON
- No errors in Render logs

✅ **Mobile App Working:**
- Login successful
- Can search tutors
- Can book sessions
- Payment works
- Video calls connect

✅ **No More Issues:**
- No WiFi problems
- No connection errors
- Works from anywhere
- Fast and reliable

---

## 📊 Progress Tracker

```
Phase 1: GitHub          [ ] Not Started  [ ] In Progress  [ ] Complete
Phase 2: Render          [ ] Not Started  [ ] In Progress  [ ] Complete
Phase 3: Test Deploy     [ ] Not Started  [ ] In Progress  [ ] Complete
Phase 4: Update App      [ ] Not Started  [ ] In Progress  [ ] Complete
Phase 5: Test Everything [ ] Not Started  [ ] In Progress  [ ] Complete
```

---

## 🆘 Troubleshooting

### GitHub Push Fails:
→ Check you have Git installed
→ Check repository URL is correct
→ Try: `git remote -v` to verify

### Render Build Fails:
→ Check Render logs
→ Verify Root Directory is `server`
→ Check all environment variables added

### App Can't Connect:
→ Verify you updated `app_config.dart`
→ Check you rebuilt the app
→ Test Render URL in browser first

### Video Call Not Working:
→ Check AGORA_APP_ID is correct
→ Verify camera/mic permissions
→ Check internet connection

---

## 📞 Quick Reference

**GitHub:** https://github.com
**Render:** https://render.com
**Your Repo:** https://github.com/YOUR_USERNAME/tutor-booking-app
**Your API:** https://tutor-app-backend.onrender.com

**Guides:**
- `GITHUB_PUSH_COMMANDS.txt` - GitHub commands
- `🚀_RENDER_DEPLOYMENT_STEPS.md` - Full deployment guide
- `✅_READY_FOR_RENDER_DEPLOYMENT.md` - Overview

---

## 🎉 When Complete

You'll have:
- ✅ Professional cloud deployment
- ✅ Global access (no WiFi issues)
- ✅ HTTPS security
- ✅ Automatic deploys
- ✅ Working mobile app
- ✅ All features functional

**Estimated Total Time:** 30 minutes

Start now! 🚀
