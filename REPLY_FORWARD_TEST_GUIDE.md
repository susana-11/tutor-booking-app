# 🧪 Reply & Forward Feature Test Guide

## Quick Test Instructions

### Prerequisites
- Two test accounts logged in on different devices/emulators
- Active chat conversation between them

---

## Test 1: Reply Feature

### Steps:
1. **Device A**: Send a message: "Hello, how are you?"
2. **Device B**: Receive the message
3. **Device B**: Long-press on the received message
4. **Device B**: Tap "Reply" from the menu
5. **Device B**: Verify reply preview appears above input field showing:
   - Reply icon
   - Sender name
   - Original message content
   - Close button (X)
6. **Device B**: Type response: "I'm good, thanks!"
7. **Device B**: Send the message
8. **Device B**: Verify reply appears with quoted message
9. **Device A**: Verify reply is received with quoted message

### Expected Results:
✅ Reply preview appears correctly
✅ Reply preview shows original message
✅ Close button cancels reply
✅ Reply is sent with reference to original message
✅ Both users see the reply with quoted message

---

## Test 2: Forward Feature

### Steps:
1. **Device A**: Send a message: "Important information"
2. **Device B**: Receive the message
3. **Device B**: Long-press on the received message
4. **Device B**: Tap "Forward" from the menu
5. **Device B**: Verify forward sheet appears showing:
   - "Forward message to..." title
   - List of conversations
   - Current conversation is NOT in the list
6. **Device B**: Select a different conversation
7. **Device B**: Verify confirmation dialog appears
8. **Device B**: Tap "Forward"
9. **Device B**: Verify success notification appears
10. **Device B**: Navigate to the target conversation
11. **Device B**: Verify forwarded message appears

### Expected Results:
✅ Forward sheet appears with conversation list
✅ Current conversation is excluded
✅ Confirmation dialog appears
✅ Message is forwarded successfully
✅ Success notification shows recipient name
✅ Forwarded message appears in target conversation

---

## Test 3: Reply to Different Message Types

### Test 3.1: Reply to Image Message
1. **Device A**: Send an image
2. **Device B**: Long-press image message
3. **Device B**: Tap "Reply"
4. **Device B**: Verify reply preview shows image indicator
5. **Device B**: Send reply
6. **Device B**: Verify reply references image message

### Test 3.2: Reply to Voice Message
1. **Device A**: Send a voice message
2. **Device B**: Long-press voice message
3. **Device B**: Tap "Reply"
4. **Device B**: Verify reply preview shows voice indicator
5. **Device B**: Send reply
6. **Device B**: Verify reply references voice message

### Test 3.3: Reply to Call Message
1. **Device A**: Make a call (let it end)
2. **Device B**: Long-press call message
3. **Device B**: Tap "Reply"
4. **Device B**: Send reply
5. **Device B**: Verify reply references call message

---

## Test 4: Forward Different Message Types

### Test 4.1: Forward Text Message
1. **Device A**: Send text: "Test message"
2. **Device B**: Forward to another conversation
3. **Device B**: Verify text is forwarded correctly

### Test 4.2: Forward Image Message
1. **Device A**: Send an image
2. **Device B**: Forward to another conversation
3. **Device B**: Verify image is forwarded correctly
4. **Device B**: Verify image loads in target conversation

### Test 4.3: Forward Voice Message
1. **Device A**: Send a voice message
2. **Device B**: Forward to another conversation
3. **Device B**: Verify voice message is forwarded
4. **Device B**: Verify voice message plays in target conversation

---

## Test 5: Edge Cases

### Test 5.1: Cancel Reply
1. Long-press message and tap "Reply"
2. Tap close button (X) on reply preview
3. Verify reply preview disappears
4. Send a normal message
5. Verify message is sent without reply reference

### Test 5.2: Reply to Own Message
1. Long-press your own sent message
2. Tap "Reply"
3. Send reply
4. Verify you can reply to your own message

### Test 5.3: Forward to Multiple Conversations
1. Forward a message to Conversation A
2. Immediately forward same message to Conversation B
3. Verify both forwards succeed

### Test 5.4: Forward Long Message
1. Send a very long text message (500+ characters)
2. Forward it to another conversation
3. Verify entire message is forwarded

---

## Test 6: UI/UX Tests

### Test 6.1: Reply Preview Layout
- Verify reply preview doesn't overlap with input field
- Verify reply preview is scrollable if message is long
- Verify close button is easily tappable

### Test 6.2: Forward Sheet Layout
- Verify forward sheet is draggable
- Verify conversation list is scrollable
- Verify avatars load correctly
- Verify names are not truncated

### Test 6.3: Loading States
- Verify loading indicator appears when forwarding
- Verify loading indicator disappears after forward completes
- Verify error message appears if forward fails

---

## Test 7: Network Tests

### Test 7.1: Reply Offline
1. Disable internet on Device B
2. Try to reply to a message
3. Verify appropriate error message

### Test 7.2: Forward Offline
1. Disable internet on Device B
2. Try to forward a message
3. Verify appropriate error message

### Test 7.3: Reply with Slow Connection
1. Enable slow network simulation
2. Reply to a message
3. Verify reply is sent eventually
4. Verify loading state is shown

---

## 🐛 Known Issues to Watch For

1. **Reply preview not clearing**: If reply preview doesn't clear after sending, report bug
2. **Forward sheet not closing**: If forward sheet stays open after forward, report bug
3. **Duplicate forwards**: If message is forwarded multiple times, report bug
4. **Missing attachments**: If forwarded message loses attachments, report bug
5. **Wrong conversation**: If forward goes to wrong conversation, report bug

---

## 📊 Test Results Template

```
Test Date: ___________
Tester: ___________

Reply Feature:
[ ] Test 1: Basic Reply - PASS/FAIL
[ ] Test 3.1: Reply to Image - PASS/FAIL
[ ] Test 3.2: Reply to Voice - PASS/FAIL
[ ] Test 3.3: Reply to Call - PASS/FAIL
[ ] Test 5.1: Cancel Reply - PASS/FAIL
[ ] Test 5.2: Reply to Own Message - PASS/FAIL

Forward Feature:
[ ] Test 2: Basic Forward - PASS/FAIL
[ ] Test 4.1: Forward Text - PASS/FAIL
[ ] Test 4.2: Forward Image - PASS/FAIL
[ ] Test 4.3: Forward Voice - PASS/FAIL
[ ] Test 5.3: Forward Multiple - PASS/FAIL
[ ] Test 5.4: Forward Long Message - PASS/FAIL

UI/UX:
[ ] Test 6.1: Reply Preview Layout - PASS/FAIL
[ ] Test 6.2: Forward Sheet Layout - PASS/FAIL
[ ] Test 6.3: Loading States - PASS/FAIL

Network:
[ ] Test 7.1: Reply Offline - PASS/FAIL
[ ] Test 7.2: Forward Offline - PASS/FAIL
[ ] Test 7.3: Reply Slow Connection - PASS/FAIL

Notes:
_________________________________
_________________________________
_________________________________
```

---

## 🚀 Quick Start Testing

**Fastest way to test:**

1. Login as Student on Device A: `etsebruk@example.com` / `123abc`
2. Login as Tutor on Device B: `bubuam13@gmail.com` / `123abc`
3. Start a chat between them
4. Send a message from Device A
5. Long-press message on Device B → Test Reply
6. Long-press message on Device B → Test Forward

**Done!** ✅

---

**Server:** `https://tutor-app-backend-wtru.onrender.com/api`
**Test Accounts:** See above
**Status:** Ready for Testing
