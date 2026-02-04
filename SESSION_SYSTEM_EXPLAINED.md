# 📚 SESSION SYSTEM - YOUR QUESTIONS ANSWERED

## ❓ YOUR QUESTIONS

### 1️⃣ WHAT DO STUDENT AND TUTOR USE IN SESSION - VOICE, VIDEO, OR WHAT?

**ANSWER: BOTH VIDEO AND VOICE! 🎥 🎤**

The session uses **Agora RTC (Real-Time Communication)** which supports:

✅ **Video Calling** - Both parties can see each other (camera can be turned on/off)
✅ **Voice Calling** - Both parties can hear each other (microphone can be muted/unmuted)
✅ **Screen Sharing** - Possible with Agora (not yet implemented)

**Current Implementation:**
- When session starts, it initializes with `enableVideo: true`
- This means **VIDEO IS ENABLED BY DEFAULT**
- Users can:
  - Mute/unmute their microphone
  - Turn camera on/off
  - Switch between front/back camera
  - Enable/disable speakerphone

**Location in Code:**
```dart
// mobile_app/lib/features/session/screens/active_session_screen.dart
await _agoraService.joinChannel(
  token: token,
  channelName: channelName,
  uid: uid,
  enableVideo: true,  // ← VIDEO IS ENABLED!
);
```

---

### 2️⃣ WHY CAN STUDENTS END THE SESSION?

**ANSWER: BOTH STUDENT AND TUTOR CAN END THE SESSION! ⚠️**

**Current Design:**
- **Either party** (student OR tutor) can end the session
- This is intentional for flexibility and safety

**Why This Makes Sense:**
1. **Emergency Situations** - If something urgent happens, either party can end
2. **Technical Issues** - If connection is bad, either can end and reschedule
3. **Inappropriate Behavior** - Either party can exit if uncomfortable
4. **Session Complete** - When teaching is done, either can end

**What Happens When Session Ends:**
1. Both parties leave the Agora channel
2. Session is marked as "completed"
3. Payment is held in escrow for 24 hours
4. Both parties get notification to rate the session
5. After 24 hours, payment automatically releases to tutor

**Protection Mechanisms:**
- ✅ Confirmation dialog before ending
- ✅ Both parties notified when session ends
- ✅ Session notes can be added
- ✅ 24-hour dispute window before payment release
- ✅ Rating system to report issues

**Location in Code:**
```javascript
// server/controllers/sessionController.js
exports.endSession = async (req, res) => {
  // Verify user is part of this booking
  const isStudent = booking.studentId._id.toString() === userIdStr;
  const isTutor = booking.tutorId._id.toString() === userIdStr;

  if (!isStudent && !isTutor) {
    return res.status(403).json({
      success: false,
      message: 'You are not authorized to end this session'
    });
  }
  // ← BOTH STUDENT AND TUTOR CAN END!
}
```

---

### 3️⃣ CAN THE SESSION ACCEPT MORE THAN ONE PERSON?

**ANSWER: NO - SESSIONS ARE 1-ON-1 ONLY! 👥**

**Current Design:**
- **One Student** + **One Tutor** = **2 People Total**
- This is a **private tutoring session**, not a group class

**How It Works:**
- Each session has exactly 2 UIDs (User IDs):
  - **UID 1** = Student
  - **UID 2** = Tutor
- Agora channel is created for these 2 users only
- No one else can join the channel

**Why 1-on-1 Only:**
1. **Privacy** - Personal tutoring requires privacy
2. **Payment Model** - Student pays for 1-on-1 attention
3. **Quality** - Better learning experience with focused attention
4. **Simplicity** - Easier to manage and track

**Location in Code:**
```javascript
// server/controllers/sessionController.js
const uid = isStudent ? 1 : 2;  // ← ONLY 2 UIDs: 1 for student, 2 for tutor
const token = generateAgoraToken(channelName, uid);
```

---

## 🎯 SUMMARY

| Question | Answer |
|----------|--------|
| **Communication Type** | Video + Voice (both enabled) |
| **Who Can End Session** | Both Student AND Tutor |
| **Max Participants** | 2 people only (1 student + 1 tutor) |

---

## 🔧 POTENTIAL IMPROVEMENTS

If you want to change these behaviors:

### 1. Make Sessions Voice-Only (No Video)
```dart
// Change in active_session_screen.dart
await _agoraService.joinChannel(
  token: token,
  channelName: channelName,
  uid: uid,
  enableVideo: false,  // ← Change to false
);
```

### 2. Only Tutor Can End Session
```javascript
// Change in sessionController.js
if (!isTutor) {
  return res.status(403).json({
    success: false,
    message: 'Only the tutor can end this session'
  });
}
```

### 3. Support Group Sessions (Multiple Students)
This would require:
- Major changes to booking model
- Different UID assignment logic
- Group payment splitting
- More complex UI for multiple video feeds
- **NOT RECOMMENDED** - would be a complete redesign

---

## 📱 USER EXPERIENCE

**When Student Joins Session:**
1. Sees tutor's video (if camera on)
2. Hears tutor's voice
3. Can see session timer
4. Can add session notes
5. Can end session anytime

**When Tutor Joins Session:**
1. Sees student's video (if camera on)
2. Hears student's voice
3. Can see session timer
4. Can add session notes
5. Can end session anytime

**Both parties have equal control!**

---

## ✅ RECOMMENDATIONS

**Current Design is GOOD because:**
1. ✅ Video + Voice = Best learning experience
2. ✅ Both can end = Safety and flexibility
3. ✅ 1-on-1 only = Quality and privacy

**If you want changes, consider:**
- Add "Report Issue" button during session
- Add "Request Extension" feature
- Add "Pause Session" feature (for breaks)
- Add session recording (with consent)

---

Need any changes to the session system? Let me know! 🚀
