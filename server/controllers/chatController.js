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

    if (!content && attachments.length === 0) {
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

    // Determine file type based on mimetype
    let fileType = 'document';
    if (req.file.mimetype.startsWith('audio/')) {
      fileType = 'audio';
    } else if (req.file.mimetype.startsWith('image/')) {
      fileType = 'image';
    } else if (req.file.mimetype.startsWith('video/')) {
      fileType = 'video';
    }

    // Get file stats for size
    const fs = require('fs');
    const stats = fs.statSync(req.file.path);

    // Construct file URL (relative to server)
    const fileUrl = `/uploads/chat/${req.file.filename}`;

    res.json({
      success: true,
      data: {
        name: req.file.originalname,
        url: fileUrl,
        type: fileType,
        size: stats.size,
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

module.exports = exports;