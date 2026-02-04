const Booking = require('../models/Booking');
const notificationService = require('../services/notificationService');
const { generateAgoraToken } = require('../utils/agoraToken');

// Start a session
exports.startSession = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const userId = req.user.userId;

    const booking = await Booking.findById(bookingId)
      .populate('studentId', 'firstName lastName email')
      .populate('tutorId', 'firstName lastName email');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Verify user is part of this booking
    const userIdStr = userId.toString();
    const isStudent = booking.studentId._id.toString() === userIdStr;
    const isTutor = booking.tutorId._id.toString() === userIdStr;

    console.log('🔐 Authorization check:', {
      userId: userIdStr,
      studentId: booking.studentId._id.toString(),
      tutorId: booking.tutorId._id.toString(),
      isStudent,
      isTutor
    });

    if (!isStudent && !isTutor) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to start this session'
      });
    }

    // Check if session is already active (student joining)
    if (booking.session.isActive) {
      console.log('📱 Student joining active session');
      
      // Generate Agora credentials for the joining student
      const channelName = booking.session.agoraChannelName || `session_${bookingId}`;
      const uid = isStudent ? 1 : 2;
      const token = generateAgoraToken(channelName, uid);

      return res.json({
        success: true,
        message: 'Joining active session',
        data: {
          bookingId: booking._id,
          channelName,
          token,
          uid,
          sessionStartedAt: booking.sessionStartedAt,
          duration: booking.duration,
          otherParty: {
            id: isStudent ? booking.tutorId._id : booking.studentId._id,
            name: isStudent 
              ? `${booking.tutorId.firstName} ${booking.tutorId.lastName}`
              : `${booking.studentId.firstName} ${booking.studentId.lastName}`
          }
        }
      });
    }

    // Check if session can be started
    if (!booking.canStartSession()) {
      return res.status(400).json({
        success: false,
        message: 'Session cannot be started at this time. Please wait until the scheduled time.'
      });
    }

    // Generate Agora credentials
    const channelName = `session_${bookingId}`;
    const uid = isStudent ? 1 : 2;
    const token = generateAgoraToken(channelName, uid);

    // Start the session
    await booking.startSession(userId, channelName, token, uid);

    // Notify the other party
    const otherPartyId = isStudent ? booking.tutorId.userId || booking.tutorId._id : booking.studentId._id;
    const starterName = isStudent 
      ? `${booking.studentId.firstName} ${booking.studentId.lastName}`
      : `${booking.tutorId.firstName} ${booking.tutorId.lastName}`;

    await notificationService.createNotification({
      userId: otherPartyId,
      type: 'session_started',
      title: 'Session Started',
      body: `${starterName} has started the session. Join now!`,
      data: { 
        bookingId: bookingId,
        channelName,
        token,
        uid: isStudent ? 2 : 1
      },
      priority: 'urgent'
    });

    res.json({
      success: true,
      message: 'Session started successfully',
      data: {
        bookingId: booking._id,
        channelName,
        token,
        uid,
        sessionStartedAt: booking.sessionStartedAt,
        duration: booking.duration,
        otherParty: {
          id: otherPartyId,
          name: isStudent 
            ? `${booking.tutorId.firstName} ${booking.tutorId.lastName}`
            : `${booking.studentId.firstName} ${booking.studentId.lastName}`
        }
      }
    });
  } catch (error) {
    console.error('Start session error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to start session'
    });
  }
};

// Join an active session
exports.joinSession = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const userId = req.user.userId;

    const booking = await Booking.findById(bookingId)
      .populate('studentId', 'firstName lastName email')
      .populate('tutorId', 'firstName lastName email');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Verify user is part of this booking
    const userIdStr = userId.toString();
    const isStudent = booking.studentId._id.toString() === userIdStr;
    const isTutor = booking.tutorId._id.toString() === userIdStr;

    if (!isStudent && !isTutor) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to join this session'
      });
    }

    if (!booking.session.isActive) {
      return res.status(400).json({
        success: false,
        message: 'Session is not active'
      });
    }

    // Generate token for joining
    const uid = isStudent ? 1 : 2;
    const token = booking.session.agoraToken || generateAgoraToken(booking.session.agoraChannelName, uid);

    // Confirm attendance
    const userRole = isStudent ? 'student' : 'tutor';
    await booking.confirmAttendance(userId, userRole);

    res.json({
      success: true,
      message: 'Joined session successfully',
      data: {
        bookingId: booking._id,
        channelName: booking.session.agoraChannelName,
        token,
        uid,
        sessionStartedAt: booking.sessionStartedAt,
        duration: booking.duration,
        otherParty: {
          id: isStudent ? booking.tutorId._id : booking.studentId._id,
          name: isStudent 
            ? `${booking.tutorId.firstName} ${booking.tutorId.lastName}`
            : `${booking.studentId.firstName} ${booking.studentId.lastName}`
        }
      }
    });
  } catch (error) {
    console.error('Join session error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to join session'
    });
  }
};

// End a session
exports.endSession = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const userId = req.user.userId;
    const { sessionNotes } = req.body;

    const booking = await Booking.findById(bookingId)
      .populate('studentId', 'firstName lastName email')
      .populate('tutorId', 'firstName lastName email');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Verify user is part of this booking
    const userIdStr = userId.toString();
    const isStudent = booking.studentId._id.toString() === userIdStr;
    const isTutor = booking.tutorId._id.toString() === userIdStr;

    if (!isStudent && !isTutor) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to end this session'
      });
    }

    console.log('📊 Session state before ending:', {
      bookingId,
      'session.isActive': booking.session?.isActive,
      'session.startedBy': booking.session?.startedBy,
      status: booking.status
    });

    // End the session
    await booking.endSession(userId);

    if (sessionNotes) {
      booking.sessionNotes = sessionNotes;
      await booking.save();
    }

    // Notify the other party
    const otherPartyId = isStudent ? booking.tutorId.userId || booking.tutorId._id : booking.studentId._id;
    const enderName = isStudent 
      ? `${booking.studentId.firstName} ${booking.studentId.lastName}`
      : `${booking.tutorId.firstName} ${booking.tutorId.lastName}`;

    await notificationService.createNotification({
      userId: otherPartyId,
      type: 'session_ended',
      title: 'Session Ended',
      body: `${enderName} has ended the session.`,
      data: { bookingId: bookingId },
      priority: 'high'
    });

    // Send rating request notifications
    await notificationService.createNotification({
      userId: booking.studentId._id,
      type: 'rating_request',
      title: 'Rate Your Session ⭐',
      body: `How was your session? Please rate your experience.`,
      data: { bookingId: bookingId },
      priority: 'normal'
    });

    await notificationService.createNotification({
      userId: booking.tutorId.userId || booking.tutorId._id,
      type: 'rating_request',
      title: 'Rate Your Session ⭐',
      body: `How was your session? Please rate your experience.`,
      data: { bookingId: bookingId },
      priority: 'normal'
    });

    res.json({
      success: true,
      message: 'Session ended successfully',
      data: {
        bookingId: booking._id,
        sessionEndedAt: booking.sessionEndedAt,
        actualDuration: booking.actualDuration,
        status: booking.status,
        escrowReleaseScheduledFor: booking.escrow.releaseScheduledFor
      }
    });
  } catch (error) {
    console.error('End session error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to end session'
    });
  }
};

// Get session status
exports.getSessionStatus = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const userId = req.user.userId;

    const booking = await Booking.findById(bookingId)
      .populate('studentId', 'firstName lastName email')
      .populate('tutorId', 'firstName lastName email');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Verify user is part of this booking
    const isStudent = booking.studentId._id.toString() === userId;
    const isTutor = booking.tutorId.userId?.toString() === userId || booking.tutorId._id.toString() === userId;

    if (!isStudent && !isTutor) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to view this session'
      });
    }

    res.json({
      success: true,
      data: {
        bookingId: booking._id,
        status: booking.status,
        canStart: booking.canStartSession(),
        session: {
          isActive: booking.session.isActive,
          startedAt: booking.sessionStartedAt,
          endedAt: booking.sessionEndedAt,
          duration: booking.duration,
          actualDuration: booking.actualDuration,
          channelName: booking.session.agoraChannelName,
          attendanceConfirmed: booking.session.attendanceConfirmed
        },
        escrow: {
          status: booking.escrow.status,
          releaseScheduledFor: booking.escrow.releaseScheduledFor
        },
        sessionDate: booking.sessionDate,
        startTime: booking.startTime,
        endTime: booking.endTime
      }
    });
  } catch (error) {
    console.error('Get session status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get session status'
    });
  }
};

// Release escrow (admin or automated)
exports.releaseEscrow = async (req, res) => {
  try {
    const { bookingId } = req.params;

    const booking = await Booking.findById(bookingId);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    await booking.releaseEscrow();

    // Notify tutor about payment
    await notificationService.notifyPaymentReceived({
      userId: booking.tutorId,
      amount: `ETB ${booking.tutorEarnings}`,
      bookingId: booking._id
    });

    res.json({
      success: true,
      message: 'Escrow released successfully',
      data: {
        bookingId: booking._id,
        tutorEarnings: booking.tutorEarnings,
        releasedAt: booking.escrow.releasedAt
      }
    });
  } catch (error) {
    console.error('Release escrow error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to release escrow'
    });
  }
};

module.exports = exports;
