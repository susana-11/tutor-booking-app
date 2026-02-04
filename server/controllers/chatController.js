const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const User = require('../models/User');

// Get user's conversations
exports.getConversations = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { page = 1, limit = 20, includeArchived = false } = req.query;

    console.log(`📨 Getting conversations for user: ${userId}`);

    const conversations = await Conversation.findUserConversations(userId, {
      page: parseInt(page),
      limit: parseInt(limit),
      includeArchived: includeArchived === 'true'
    });

    console.log(`📨 Found ${conversations.length} conversations`);

    // Calculate unread count for each conversation
    const conversationsWithUnread = await Promise.all(
      conversations.map(async (conversation) => {
        const unreadCount = await Message.getUnreadCount(userId, conversation._id);
        const otherParticipant = conversation.getOtherParticipant(userId);
        
        console.log(`📨 Conversation ${conversation._id}: Other participant = ${otherParticipant.userId?.firstName} ${otherParticipant.userId?.lastName}`);
        
        return {
          id: conversation._id,
          participantId: otherParticipant.userId._id,
          participantName: `${otherParticipant.userId.firstName} ${otherParticipant.userId.lastName}`,
          participantAvatar: otherParticipant.userId.profilePicture,
          participantRole: otherParticipant.role,
          subject: conversation.subject,
          lastMessage: conversation.lastMessage ? {
            id: conversation.lastMessage._id,
            senderId: conversation.lastMessage.senderId,
            senderName: conversation.lastMessage.senderId.firstName + ' ' + conversation.lastMessage.senderId.lastName,
            content: conversation.lastMessage.content,
            type: conversation.lastMessage.type,
            status: conversation.lastMessage.status,
            createdAt: conversation.lastMessage.createdAt,
            updatedAt: conversation.lastMessage.updatedAt
          } : null,
          unreadCount,
          isOnline: false, // Will be updated by socket service
          isArchived: conversation.isArchived,
          isPinned: conversation.isPinned,
          createdAt: conversation.createdAt,
          updatedAt: conversation.updatedAt
        };
      })
    );

    console.log(`✅ Returning ${conversationsWithUnread.length} conversations with unread counts`);

    res.json({
      success: true,
      data: {
        conversations: conversationsWithUnread,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: conversationsWithUnread.length
        }
      }
    });

  } catch (error) {
    console.error('❌ Get conversations error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch conversations',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Create or get conversation
exports.createOrGetConversation = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { participantId, subject } = req.body;

    if (!participantId) {
      return res.status(400).json({
        success: false,
        message: 'Participant ID is required'
      });
    }

    // Check if conversation already exists
    let conversation = await Conversation.findByParticipants(userId, participantId);

    if (!conversation) {
      // Get participant details
      const participant = await User.findById(participantId);
      if (!participant) {
        return res.status(404).json({
          success: false,
          message: 'Participant not found'
        });
      }

      // Create new conversation
      conversation = new Conversation({
        participants: [
          {
            userId: userId,
            role: req.user.role
          },
          {
            userId: participantId,
            role: participant.role
          }
        ],
        subject: subject,
        createdBy: userId
      });

      await conversation.save();
    }

    // Populate participant details
    await conversation.populate('participants.userId', 'firstName lastName email profilePicture role');

    const otherParticipant = conversation.getOtherParticipant(userId);

    res.json({
      success: true,
      data: {
        id: conversation._id,
        participantId: otherParticipant.userId._id,
        participantName: `${otherParticipant.userId.firstName} ${otherParticipant.userId.lastName}`,
        participantAvatar: otherParticipant.userId.profilePicture,
        participantRole: otherParticipant.role,
        subject: conversation.subject,
        createdAt: conversation.createdAt,
        updatedAt: conversation.updatedAt
      }
    });

  } catch (error) {
    console.error('Create conversation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create conversation',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get messages for a conversation
exports.getMessages = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { conversationId } = req.params;
    const { page = 1, limit = 50, before } = req.query;

    // Verify user is participant in conversation
    const conversation = await Conversation.findById(conversationId);
    if (!conversation || !conversation.getParticipant(userId)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied to this conversation'
      });
    }

    const messages = await Message.findConversationMessages(conversationId, {
      page: parseInt(page),
      limit: parseInt(limit),
      before
    });

    // Format messages for response
    const formattedMessages = messages.reverse().map(message => ({
      id: message._id,
      conversationId: message.conversationId,
      senderId: message.senderId._id,
      senderName: `${message.senderId.firstName} ${message.senderId.lastName}`,
      content: message.content,
      type: message.type,
      status: message.status,
      attachments: message.attachments,
      replyTo: message.replyTo ? {
        id: message.replyTo._id,
        content: message.replyTo.content,
        senderName: message.replyTo.senderId ? 
          `${message.replyTo.senderId.firstName} ${message.replyTo.senderId.lastName}` : 
          'Unknown'
      } : null,
      isEdited: message.isEdited,
      editedAt: message.editedAt,
      createdAt: message.createdAt,
      updatedAt: message.updatedAt
    }));

    res.json({
      success: true,
      data: {
        messages: formattedMessages,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          hasMore: messages.length === parseInt(limit)
        }
      }
    });

  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch messages',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Send message
exports.sendMessage = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { conversationId } = req.params;
    const { content, type = 'text', attachments = [], replyToId } = req.body;

    // Validate that either content or attachments are provided
    if ((!content || content.trim() === '') && (!attachments || attachments.length === 0)) {
      return res.status(400).json({
        success: false,
        message: 'Message content or attachments required'
      });
    }

    // Verify user is participant in conversation
    const conversation = await Conversation.findById(conversationId);
    if (!conversation || !conversation.getParticipant(userId)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied to this conversation'
      });
    }

    // Create message
    const message = new Message({
      conversationId,
      senderId: userId,
      content: content || '',
      type,
      attachments,
      replyTo: replyToId || undefined
    });

    await message.save();

    // Populate sender details
    await message.populate('senderId', 'firstName lastName profilePicture');
    if (replyToId) {
      await message.populate('replyTo');
    }

    // Update conversation last activity
    await conversation.updateLastActivity();

    // Format response
    const formattedMessage = {
      id: message._id,
      conversationId: message.conversationId,
      senderId: message.senderId._id,
      senderName: `${message.senderId.firstName} ${message.senderId.lastName}`,
      content: message.content,
      type: message.type,
      status: message.status,
      attachments: message.attachments,
      replyTo: message.replyTo ? {
        id: message.replyTo._id,
        content: message.replyTo.content,
        senderName: message.replyTo.senderId ? 
          `${message.replyTo.senderId.firstName} ${message.replyTo.senderId.lastName}` : 
          'Unknown'
      } : null,
      isEdited: message.isEdited,
      editedAt: message.editedAt,
      createdAt: message.createdAt,
      updatedAt: message.updatedAt
    };

    // ✅ EMIT SOCKET EVENT TO OTHER PARTICIPANTS
    try {
      const io = req.app.get('io');
      if (io) {
        console.log(`💬 Attempting to emit socket event for conversation: ${conversationId}`);
        console.log(`💬 Current user ID: ${userId}`);
        console.log(`💬 Conversation participants:`, conversation.participants.map(p => ({
          userId: p.userId._id || p.userId,
          role: p.role
        })));
        
        // Find the other participant (not the sender)
        const recipientParticipant = conversation.participants.find(p => {
          const participantId = p.userId._id ? p.userId._id.toString() : p.userId.toString();
          const currentUserId = userId.toString();
          console.log(`💬 Comparing: ${participantId} !== ${currentUserId}`);
          return participantId !== currentUserId;
        });
        
        if (recipientParticipant) {
          const recipientId = recipientParticipant.userId._id 
            ? recipientParticipant.userId._id.toString() 
            : recipientParticipant.userId.toString();
          
          console.log(`💬 Found recipient: ${recipientId}`);
          console.log(`💬 Emitting to room: user_${recipientId}`);
          
          // Emit to recipient's room
          io.to(`user_${recipientId}`).emit('new_message', formattedMessage);
          console.log(`✅ Socket event emitted to user_${recipientId}`);
          
          // Also emit to conversation room
          io.to(`chat_${conversationId}`).emit('new_message', formattedMessage);
          console.log(`✅ Socket event emitted to chat_${conversationId}`);
        } else {
          console.error(`❌ Could not find recipient in conversation ${conversationId}`);
          console.error(`❌ Participants:`, JSON.stringify(conversation.participants, null, 2));
        }
      } else {
        console.error('❌ Socket.IO not available!');
      }
    } catch (socketError) {
      console.error('❌ Socket emit error:', socketError);
      console.error('❌ Error stack:', socketError.stack);
    }

    res.status(201).json({
      success: true,
      message: 'Message sent successfully',
      data: formattedMessage
    });

  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send message',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Mark conversation as read
exports.markAsRead = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { conversationId } = req.params;

    // Verify user is participant in conversation
    const conversation = await Conversation.findById(conversationId);
    if (!conversation || !conversation.getParticipant(userId)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied to this conversation'
      });
    }

    // Mark all unread messages as read
    await Message.markConversationAsRead(conversationId, userId);

    // Update participant's last read timestamp
    await conversation.markAsRead(userId);

    res.json({
      success: true,
      message: 'Messages marked as read'
    });

  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark messages as read',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get unread message count
exports.getUnreadCount = async (req, res) => {
  try {
    const userId = req.user.userId;

    const unreadCount = await Message.getUnreadCount(userId);

    res.json({
      success: true,
      data: {
        count: unreadCount
      }
    });

  } catch (error) {
    console.error('Get unread count error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get unread count',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Archive conversation
exports.archiveConversation = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { conversationId } = req.params;

    const conversation = await Conversation.findById(conversationId);
    if (!conversation || !conversation.getParticipant(userId)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied to this conversation'
      });
    }

    conversation.isArchived = true;
    await conversation.save();

    res.json({
      success: true,
      message: 'Conversation archived successfully'
    });

  } catch (error) {
    console.error('Archive conversation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to archive conversation',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Pin/Unpin conversation
exports.pinConversation = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { conversationId } = req.params;
    const { isPinned } = req.body;

    const conversation = await Conversation.findById(conversationId);
    if (!conversation || !conversation.getParticipant(userId)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied to this conversation'
      });
    }

    conversation.isPinned = isPinned;
    await conversation.save();

    res.json({
      success: true,
      message: `Conversation ${isPinned ? 'pinned' : 'unpinned'} successfully`
    });

  } catch (error) {
    console.error('Pin conversation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to pin conversation',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Delete conversation
exports.deleteConversation = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { conversationId } = req.params;

    const conversation = await Conversation.findById(conversationId);
    if (!conversation || !conversation.getParticipant(userId)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied to this conversation'
      });
    }

    // Soft delete - mark as inactive
    conversation.isActive = false;
    await conversation.save();

    res.json({
      success: true,
      message: 'Conversation deleted successfully'
    });

  } catch (error) {
    console.error('Delete conversation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete conversation',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Search messages
exports.searchMessages = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { query, conversationId, page = 1, limit = 20 } = req.query;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    const messages = await Message.searchMessages(query, userId, {
      conversationId,
      page: parseInt(page),
      limit: parseInt(limit)
    });

    // Format messages for response
    const formattedMessages = messages.map(message => ({
      id: message._id,
      conversationId: message.conversationId,
      senderId: message.senderId._id,
      senderName: `${message.senderId.firstName} ${message.senderId.lastName}`,
      content: message.content,
      type: message.type,
      createdAt: message.createdAt
    }));

    res.json({
      success: true,
      data: {
        messages: formattedMessages,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: formattedMessages.length
        }
      }
    });

  } catch (error) {
    console.error('Search messages error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search messages',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Upload attachment
exports.uploadAttachment = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    // Cloudinary automatically uploads and returns URL
    const fileUrl = req.file.path; // This is the full Cloudinary URL
    
    // Determine file type based on mimetype
    let fileType = 'document';
    if (req.file.mimetype.startsWith('audio/')) {
      fileType = 'audio';
    } else if (req.file.mimetype.startsWith('image/')) {
      fileType = 'image';
    } else if (req.file.mimetype.startsWith('video/')) {
      fileType = 'video';
    }

    console.log(`✅ File uploaded to Cloudinary: ${fileUrl}`);

    res.json({
      success: true,
      data: {
        name: req.file.originalname,
        url: fileUrl, // Full Cloudinary URL (permanent)
        type: fileType,
        size: req.file.size,
        mimeType: req.file.mimetype
      }
    });

  } catch (error) {
    console.error('Upload attachment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload attachment',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Report user
exports.reportUser = async (req, res) => {
  try {
    const reporterId = req.user.userId;
    const { reportedUserId, reportedUserName, reason, details, conversationId } = req.body;

    console.log(`🚨 User ${reporterId} reporting user ${reportedUserId} for: ${reason}`);

    // Validate input
    if (!reportedUserId || !reason) {
      return res.status(400).json({
        success: false,
        message: 'Reported user ID and reason are required'
      });
    }

    // Get reporter info
    const reporter = await User.findById(reporterId);
    if (!reporter) {
      return res.status(404).json({
        success: false,
        message: 'Reporter not found'
      });
    }

    // Create report notification for admin
    const notificationService = require('../services/notificationService');
    
    // Find all admin users
    const admins = await User.find({ role: 'admin' });
    
    // Send notification to all admins
    for (const admin of admins) {
      await notificationService.createNotification({
        userId: admin._id,
        type: 'user_report',
        title: '🚨 User Report',
        body: `${reporter.firstName} ${reporter.lastName} reported ${reportedUserName || 'a user'} for ${reason}`,
        data: {
          reporterId,
          reporterName: `${reporter.firstName} ${reporter.lastName}`,
          reportedUserId,
          reportedUserName,
          reason,
          details,
          conversationId,
          timestamp: new Date()
        },
        priority: 'high'
      });
    }

    console.log(`✅ Report sent to ${admins.length} admin(s)`);

    res.json({
      success: true,
      message: 'Report submitted successfully. Our team will review it shortly.'
    });

  } catch (error) {
    console.error('Report user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit report',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Clear chat messages
exports.clearChat = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { conversationId } = req.params;

    console.log(`🗑️ User ${userId} clearing chat ${conversationId}`);

    // Verify user is part of the conversation
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found'
      });
    }

    // Check if user is a participant - ensure both IDs are strings for comparison
    const isParticipant = conversation.participants.some(
      p => p.userId.toString() === userId.toString()
    );

    if (!isParticipant) {
      console.log(`❌ User ${userId} not authorized - not a participant`);
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to clear this conversation'
      });
    }

    // Delete all messages in the conversation for this user
    // Note: This only marks messages as deleted for this user, not permanently deleted
    await Message.updateMany(
      { conversationId },
      { $addToSet: { deletedFor: userId } }
    );

    // Update conversation last message
    conversation.lastMessage = null;
    await conversation.save();

    console.log(`✅ Chat cleared for user ${userId}`);

    res.json({
      success: true,
      message: 'Chat cleared successfully'
    });

  } catch (error) {
    console.error('Clear chat error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to clear chat',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

module.exports = exports;