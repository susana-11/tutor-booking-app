# 📋 Reply & Forward Quick Reference

## 🚀 Quick Start

### To Reply:
1. **Long-press** message
2. Tap **"Reply"**
3. Type response
4. **Send**

### To Forward:
1. **Long-press** message
2. Tap **"Forward"**
3. Select conversation
4. **Confirm**

---

## 🎯 Features at a Glance

| Feature | Status | Description |
|---------|--------|-------------|
| Reply to Text | ✅ | Quote and respond to text messages |
| Reply to Image | ✅ | Quote and respond to image messages |
| Reply to Voice | ✅ | Quote and respond to voice messages |
| Reply to Call | ✅ | Quote and respond to call messages |
| Forward Text | ✅ | Forward text to other conversations |
| Forward Image | ✅ | Forward images with attachments |
| Forward Voice | ✅ | Forward voice messages |
| Cancel Reply | ✅ | Close button to cancel reply |
| Multiple Forward | ✅ | Forward same message multiple times |

---

## 🎨 UI Elements

### Reply Preview
```
┌─────────────────────────────┐
│ ↩️ Replying to John      ❌ │
│ Hello, how are you?         │
└─────────────────────────────┘
```

### Forward Sheet
```
┌─────────────────────────────┐
│ ❌ Forward message to...    │
├─────────────────────────────┤
│ 👤 Sarah Johnson            │
│ 👤 Mike Wilson              │
│ 👤 Emma Davis               │
└─────────────────────────────┘
```

---

## 🔧 Technical Quick Ref

### Reply Code:
```dart
// Set reply
setState(() => _replyingTo = message);

// Send
await _chatService.sendMessage(
  conversationId: id,
  content: content,
  replyToId: _replyingTo?.id,
);
```

### Forward Code:
```dart
// Forward
await _chatService.sendMessage(
  conversationId: targetId,
  content: message.content,
  type: message.type,
  attachments: message.attachments,
);
```

---

## 📱 Test Accounts

| Role | Email | Password |
|------|-------|----------|
| Tutor | bubuam13@gmail.com | 123abc |
| Student | etsebruk@example.com | 123abc |

**Server:** `https://tutor-app-backend-wtru.onrender.com/api`

---

## ✅ Quick Test

1. Login as Student (Device A)
2. Login as Tutor (Device B)
3. Send message from A
4. Long-press on B → Reply
5. Long-press on B → Forward

**Done!** ✅

---

## 📚 Full Documentation

- **Implementation:** `REPLY_FORWARD_COMPLETE.md`
- **Testing:** `REPLY_FORWARD_TEST_GUIDE.md`
- **Visual Guide:** `REPLY_FORWARD_VISUAL_GUIDE.md`
- **Deployment:** `DEPLOY_REPLY_FORWARD.md`
- **Summary:** `TASK_7_COMPLETE.md`

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Reply preview not showing | Check `_replyingTo` state |
| Forward sheet empty | Refresh conversations |
| Message not forwarding | Check network connection |
| Reply not clearing | Tap close button (X) |

---

## 📊 Status

**Implementation:** ✅ Complete  
**Testing:** ⏳ Pending  
**Deployment:** ⏳ Pending  

---

**Last Updated:** February 3, 2026
