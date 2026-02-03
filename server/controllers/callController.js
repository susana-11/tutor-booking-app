const Call = require('../models/Call');
const User = require('../models/User');
const { v4: uuidv4 } = require('uuid');
const { generateAgoraToken, generateChannelName, objectIdToUid } = require('../utils/agoraToken');

// Initiate a call
exports.initiateCall = async (req, res) => {
  try {
    const { receiverId, callType, bookingId } = req.body;
    const initiatorId = req.user.userId; // Fixed: use userId instead of id

    // Validate call type
    if (!['voice', 'video'].includes(callType)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid call type. Must be "voice" or "video"'
      });
    }

    // Check if receiver exists
    const receiver = await User.findById(receiverId);
    if (!receiver) {
      return res.status(404).json({
        success: false,
        message: 'Receiver not found'
      });
    }

    // Check if user is calling themselves
    if (initiatorId === receiverId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot call yourself'
      });
    }

    // Generate unique identifiers
    const callId = uuidv4();
    const channelName = generateChannelName(initiatorId, receiverId);
    
    // Convert user IDs to numeric UIDs for Agora
    const initiatorUid = objectIdToUid(initiatorId);
    const receiverUid = objectIdToUid(receiverId);

    // Generate Agora tokens
    const initiatorToken = generateAgoraToken(channelName, initiatorUid, 'publisher');
    const receiverToken = generateAgoraToken(channelName, receiverUid, 'publisher');

    // Create call record
    const call = await Call.create({
      callId,
      channelName,
      callType,
      initiatorId,
      receiverId,
      bookingId,
      status: 'initiated',
      initiatorToken,
      receiverToken
    });

    // Populate user details
    await call.populate('initiatorId', 'firstName lastName profilePicture');
    await call.populate('receiverId', 'firstName lastName profilePicture');

    // Send call notification via Socket.IO
    const io = req.app.get('io');
    if (io) {
      io.to(receiverId).emit('incoming_call', {
        callId: call.callId,
        channelName: call.channelName,
        callType: call.callType,
        initiator: {
          id: req.user.userId,
          name: `${req.user.firstName} ${req.user.lastName}`,
          avatar: req.user.profilePicture
        },
        token: receiverToken,
        uid: receiverUid
      });
    }

    console.log(`📞 Call initiated: ${callType} call from ${initiatorId} to ${receiverId}`);

    res.json({
      success: true,
      data: {
        callId: call.callId,
        channelName: call.channelName,
        token: initiatorToken,
        uid: initiatorUid,
        callType: call.callType,
        receiver: {
          id: receiver._id,
          name: `${receiver.firstName} ${receiver.lastName}`,
          avatar: receiver.profilePicture
        }
      }
    });

  } catch (error) {
    console.error('Initiate call error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to initiate call',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Answer a call
exports.answerCall = async (req, res) => {
  try {
    const { callId } = req.params;
    const userId = req.user.userId;

    const call = await Call.findOne({ callId });
    
    if (!call) {
      return res.status(404).json({
        success: false,
        message: 'Call not found'
      });
    }

    // Verify user is the receiver
    if (call.receiverId.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to answer this call'
      });
    }

    // Update call status
    call.status = 'answered';
    call.startTime = new Date();
    await call.save();

    // Notify initiator via Socket.IO
    const io = req.app.get('io');
    if (io) {
      io.to(call.initiatorId.toString()).emit('call_answered', {
        callId: call.callId
      });
    }

    console.log(`✅ Call answered: ${callId}`);

    res.json({
      success: true,
      message: 'Call answered',
      data: {
        callId: call.callId,
        startTime: call.startTime
      }
    });

  } catch (error) {
    console.error('Answer call error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to answer call',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Reject a call
exports.rejectCall = async (req, res) => {
  try {
    const { callId } = req.params;
    const userId = req.user.userId;

    const call = await Call.findOne({ callId });
    
    if (!call) {
      return res.status(404).json({
        success: false,
        message: 'Call not found'
      });
    }

    // Verify user is the receiver
    if (call.receiverId.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to reject this call'
      });
    }

    // Update call status
    call.status = 'rejected';
    call.endTime = new Date();
    call.metadata = { ...call.metadata, endReason: 'rejected' };
    await call.save();

    // Notify initiator via Socket.IO
    const io = req.app.get('io');
    if (io) {
      io.to(call.initiatorId.toString()).emit('call_rejected', {
        callId: call.callId
      });
    }

    console.log(`❌ Call rejected: ${callId}`);

    res.json({
      success: true,
      message: 'Call rejected'
    });

  } catch (error) {
    console.error('Reject call error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reject call',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// End a call
exports.endCall = async (req, res) => {
  try {
    const { callId } = req.params;
    const userId = req.user.userId;

    const call = await Call.findOne({ callId });
    
    if (!call) {
      return res.status(404).json({
        success: false,
        message: 'Call not found'
      });
    }

    // Verify user is part of the call (convert both to strings for comparison)
    const initiatorIdStr = call.initiatorId.toString();
    const receiverIdStr = call.receiverId.toString();
    const userIdStr = userId.toString();

    if (initiatorIdStr !== userIdStr && receiverIdStr !== userIdStr) {
      console.log(`❌ Authorization failed: userId=${userIdStr}, initiatorId=${initiatorIdStr}, receiverId=${receiverIdStr}`);
      return res.status(403).json({
        success: false,
        message: 'Not authorized to end this call'
      });
    }

    // Update call status
    call.status = 'ended';
    call.endTime = new Date();
    call.calculateDuration();
    call.metadata = { ...call.metadata, endReason: 'normal' };
    await call.save();

    // Notify other participant via Socket.IO
    const io = req.app.get('io');
    if (io) {
      const otherUserId = initiatorIdStr === userIdStr 
        ? receiverIdStr 
        : initiatorIdStr;
      
      io.to(otherUserId).emit('call_ended', {
        callId: call.callId,
        duration: call.duration
      });
    }

    console.log(`📴 Call ended: ${callId}, Duration: ${call.duration}s`);

    res.json({
      success: true,
      message: 'Call ended',
      data: {
        callId: call.callId,
        duration: call.duration,
        startTime: call.startTime,
        endTime: call.endTime
      }
    });

  } catch (error) {
    console.error('End call error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to end call',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get call history
exports.getCallHistory = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { page = 1, limit = 20, callType, status } = req.query;

    const calls = await Call.getCallHistory(userId, {
      page: parseInt(page),
      limit: parseInt(limit),
      callType,
      status
    });

    const total = await Call.countDocuments({
      $or: [
        { initiatorId: userId },
        { receiverId: userId }
      ]
    });

    res.json({
      success: true,
      data: {
        calls,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });

  } catch (error) {
    console.error('Get call history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch call history',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get missed calls
exports.getMissedCalls = async (req, res) => {
  try {
    const userId = req.user.userId;

    const missedCalls = await Call.getMissedCalls(userId);

    res.json({
      success: true,
      data: {
        missedCalls,
        count: missedCalls.length
      }
    });

  } catch (error) {
    console.error('Get missed calls error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch missed calls',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get call statistics
exports.getCallStats = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { period = 'month' } = req.query;

    const stats = await Call.getCallStats(userId, period);

    res.json({
      success: true,
      data: {
        period,
        stats
      }
    });

  } catch (error) {
    console.error('Get call stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch call statistics',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

module.exports = exports;
