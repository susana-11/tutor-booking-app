# Network Setup Diagram

## 🏠 Local Network Testing Setup

```
┌─────────────────────────────────────────────────────────────┐
│                     Your WiFi Network                        │
│                                                              │
│  ┌──────────────────┐                                       │
│  │   Your Computer  │                                       │
│  │  192.168.1.5     │                                       │
│  │                  │                                       │
│  │  ┌────────────┐  │                                       │
│  │  │   Server   │  │                                       │
│  │  │  Port 5000 │  │                                       │
│  │  └────────────┘  │                                       │
│  └──────────────────┘                                       │
│           │                                                  │
│           │ WiFi Connection                                 │
│           │                                                  │
│     ┌─────┴─────┐                                           │
│     │           │                                           │
│  ┌──▼───┐   ┌──▼───┐                                       │
│  │Phone1│   │Phone2│                                       │
│  │      │   │      │                                       │
│  │Student│   │Tutor │                                       │
│  └──────┘   └──────┘                                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ Internet
                         │
                    ┌────▼────┐
                    │ MongoDB │
                    │  Atlas  │
                    │ (Cloud) │
                    └─────────┘
```

## 📱 Communication Flow

### 1. Student Books Session
```
Phone 1 (Student)
    │
    │ HTTP POST /api/bookings
    │ http://192.168.1.5:5000
    │
    ▼
Computer (Server)
    │
    │ Save to database
    │
    ▼
MongoDB Atlas (Cloud)
    │
    │ Notification
    │
    ▼
Phone 2 (Tutor)
```

### 2. Video Call Session
```
Phone 1 (Student)          Phone 2 (Tutor)
    │                           │
    │ Start Session             │ Start Session
    │                           │
    ▼                           ▼
Computer (Server) ◄─────────────┘
    │
    │ Generate Agora Token
    │
    ├──────────────┬────────────┐
    │              │            │
    ▼              ▼            ▼
Phone 1        Phone 2      Agora Cloud
    │              │            │
    └──────────────┴────────────┘
         Video/Audio Stream
```

## ☁️ Cloud Deployment Setup

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
│                                                              │
│  ┌──────────────────┐                                       │
│  │   Render.com     │                                       │
│  │                  │                                       │
│  │  ┌────────────┐  │                                       │
│  │  │   Server   │  │                                       │
│  │  │  Port 443  │  │                                       │
│  │  └────────────┘  │                                       │
│  └──────────────────┘                                       │
│           │                                                  │
│           │ HTTPS                                           │
│           │                                                  │
│     ┌─────┴─────┐                                           │
│     │           │                                           │
│  ┌──▼───┐   ┌──▼───┐                                       │
│  │Phone1│   │Phone2│                                       │
│  │      │   │      │                                       │
│  │Student│   │Tutor │                                       │
│  │(WiFi)│   │(4G)  │                                       │
│  └──────┘   └──────┘                                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                         │
                         │
                    ┌────▼────┐
                    │ MongoDB │
                    │  Atlas  │
                    │ (Cloud) │
                    └─────────┘
```

## 🔄 Data Flow

### Local Network:
```
Phone → WiFi → Computer → Internet → MongoDB Atlas
                  ↓
              Server (Node.js)
```

### Cloud:
```
Phone → Internet → Render.com → MongoDB Atlas
                      ↓
                  Server (Node.js)
```

## 🔐 Security

### Local Network:
- ✅ Private WiFi network
- ✅ Firewall protection
- ⚠️ HTTP (not encrypted)
- ⚠️ Only accessible on local network

### Cloud:
- ✅ HTTPS (encrypted)
- ✅ Accessible anywhere
- ✅ DDoS protection
- ✅ SSL certificate

## 📊 Comparison

| Aspect | Local Network | Cloud |
|--------|--------------|-------|
| **Setup** | 5 minutes | 15 minutes |
| **Access** | Same WiFi only | Anywhere |
| **Speed** | Very fast | Fast |
| **Cost** | Free | Free (with limits) |
| **Security** | Private network | HTTPS |
| **Reliability** | Depends on computer | 99.9% uptime |
| **Best for** | Quick testing | Long-term use |

## 🎯 Current Configuration

You are currently set up for: **Local Network Testing**

```
Mobile App Config:
baseUrl = 'http://192.168.1.5:5000/api'

Server:
Running on: http://192.168.1.5:5000
Database: MongoDB Atlas (cloud)

Phones:
Must be on same WiFi as computer
```

## 🔄 To Switch to Cloud

1. Deploy server to Render.com
2. Update mobile app:
   ```dart
   baseUrl = 'https://tutor-app-backend.onrender.com/api'
   ```
3. Rebuild and reinstall app

See: `CLOUD_DEPLOYMENT_GUIDE.md`
