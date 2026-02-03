# 🔧 Connection Troubleshooting Guide

## ❌ Problem: Phone Cannot Connect to Server

You're seeing: `❌ ERROR: null` and `📥 ERROR DATA: null`

This means your phone **cannot reach** the server at `http://192.168.1.5:5000`

---

## ✅ Step-by-Step Fix

### Step 1: Verify WiFi Connection (MOST IMPORTANT)

**Your computer WiFi:** `Sifrash`

**On your phone:**
1. Open Settings → WiFi
2. Check connected network name
3. **MUST be:** `Sifrash` (same as computer)
4. **NOT:** Mobile data, different WiFi, or hotspot

**If phone is on different WiFi:**
- Disconnect and connect to `Sifrash`
- Restart the app

---

### Step 2: Test Server from Phone Browser

**On your phone, open browser (Chrome/Firefox):**

Visit: `http://192.168.1.5:5000`

**Expected Results:**

✅ **Success:** You see `{"message":"Route not found"}`
- Server is reachable!
- Problem is in the app
- Try restarting the app

❌ **Failure:** "Can't reach this page" or timeout
- Phone cannot reach server
- Continue to Step 3

---

### Step 3: Check Server is Running

**On your computer:**

```bash
# Check if server is running
cd server
npm start
```

You should see:
```
🚀 Server running on port 5000
✅ MongoDB Connected
```

**If not running:** Start it with `start-server.bat` or `cd server && npm start`

---

### Step 4: Verify Firewall (Already Fixed)

✅ Firewall rules have been updated to allow connections on port 5000

If still not working, temporarily disable Windows Firewall:
1. Windows Security → Firewall & network protection
2. Turn off for Private network (temporarily)
3. Test connection
4. Turn back on after testing

---

### Step 5: Check Router Settings

Some routers block device-to-device communication (AP Isolation).

**To check:**
1. Open router admin page (usually `192.168.1.1` or `192.168.0.1`)
2. Look for "AP Isolation" or "Client Isolation"
3. Make sure it's **DISABLED**

**Common router admin URLs:**
- `http://192.168.1.1`
- `http://192.168.0.1`
- `http://192.168.1.254`

---

### Step 6: Try Alternative IP Address

Your computer might have multiple network adapters. Let's check all IPs:

**On your computer:**
```cmd
ipconfig
```

Look for all IPv4 addresses and try each one in the app.

**Common patterns:**
- `192.168.1.x`
- `192.168.0.x`
- `10.0.0.x`

---

## 🔄 Alternative: Use Computer's Hotspot

If WiFi router is blocking connections:

**On your computer:**
1. Settings → Network & Internet → Mobile hotspot
2. Turn on "Share my Internet connection"
3. Note the network name and password
4. Connect your phone to this hotspot
5. Find new IP: `ipconfig` (look for "Wireless LAN adapter Local Area Connection")
6. Update app config with new IP

---

## 🧪 Quick Tests

### Test 1: Ping from Phone to Computer

**On phone (using Termux or similar):**
```bash
ping 192.168.1.5
```

✅ **Success:** You get replies
❌ **Failure:** "Request timeout" → Network issue

### Test 2: Test from Computer Browser

**On your computer, open browser:**
```
http://192.168.1.5:5000/api/auth/login
```

Should show: `Cannot GET /api/auth/login` (this is correct - it needs POST)

### Test 3: Test Login from Computer

**PowerShell:**
```powershell
$body = @{email='bubuam13@gmail.com';password='123abc'} | ConvertTo-Json
Invoke-RestMethod -Uri 'http://192.168.1.5:5000/api/auth/login' -Method Post -Body $body -ContentType 'application/json'
```

✅ **Success:** You get token
❌ **Failure:** Server not working

---

## 📱 Current Configuration

```yaml
Computer:
  IP: 192.168.1.5
  WiFi: Sifrash
  Server: Running on port 5000
  Firewall: Configured ✅

Phone:
  WiFi: ??? (Check this!)
  App URL: http://192.168.1.5:5000/api
  
Required:
  Phone WiFi MUST be: Sifrash
```

---

## ✅ Checklist

Before testing, verify:

- [ ] Server is running (`cd server && npm start`)
- [ ] Computer WiFi: `Sifrash`
- [ ] Phone WiFi: `Sifrash` (SAME as computer)
- [ ] Phone browser can access `http://192.168.1.5:5000`
- [ ] Firewall allows port 5000
- [ ] Router AP Isolation is OFF

---

## 🆘 Still Not Working?

### Option 1: Use Cloud Deployment

Deploy to Render.com so you don't need local network:
→ See `CLOUD_DEPLOYMENT_GUIDE.md`

### Option 2: Use Emulator

Test on Android emulator instead of physical device:
```bash
flutter run
```

Emulator uses `10.0.2.2` which always works.

### Option 3: Check Detailed Logs

**On phone (if connected via USB):**
```bash
flutter logs
```

Look for more detailed error messages.

---

## 🎯 Most Common Solution

**90% of the time, the issue is:**

Your phone is on **mobile data** or **different WiFi** instead of the same WiFi as your computer.

**Fix:**
1. Turn off mobile data on phone
2. Connect to WiFi: `Sifrash`
3. Restart the app
4. Try login again

---

## 📞 Quick Reference

**Server URL:** `http://192.168.1.5:5000`
**API URL:** `http://192.168.1.5:5000/api`
**WiFi Name:** `Sifrash`
**Test URL:** `http://192.168.1.5:5000` (in phone browser)

**Expected browser result:** `{"message":"Route not found"}`
