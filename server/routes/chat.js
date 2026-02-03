const express = require('express');
const multer = require('multer');
const { authenticate } = require('../middleware/auth');
const chatController = require('../controllers/chatController');
const { chatStorage } = require('../config/cloudinary');

const router = express.Router();

// Configure multer to use Cloudinary storage
const upload = multer({
  storage: chatStorage,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    // Allow audio, image, video, and document files
    const allowedMimes = [
      'audio/mpeg', 'audio/mp4', 'audio/m4a', 'audio/x-m4a', 'audio/wav', 'audio/webm',
      'image/jpeg', 'image/png', 'image/gif', 'image/webp',
      'video/mp4', 'video/webm',
      'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ];
    
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only audio, images, videos, and documents are allowed.'));
    }
  }
});

// Conversation routes
router.get('/conversations', authenticate, chatController.getConversations);
router.post('/conversations', authenticate, chatController.createOrGetConversation);
router.put('/conversations/:conversationId/read', authenticate, chatController.markAsRead);
router.put('/conversations/:conversationId/archive', authenticate, chatController.archiveConversation);
router.put('/conversations/:conversationId/pin', authenticate, chatController.pinConversation);
router.delete('/conversations/:conversationId', authenticate, chatController.deleteConversation);

// Message routes
router.get('/conversations/:conversationId/messages', authenticate, chatController.getMessages);
router.post('/conversations/:conversationId/messages', authenticate, chatController.sendMessage);

// Utility routes
router.get('/unread-count', authenticate, chatController.getUnreadCount);
router.get('/search', authenticate, chatController.searchMessages);
router.post('/upload', authenticate, upload.single('file'), chatController.uploadAttachment);

// Legacy routes (keeping for backward compatibility)
// Get messages for a conversation
router.get('/conversations/:id/messages', authenticate, async (req, res) => {
  try {
    // Redirect to new endpoint
    req.params.conversationId = req.params.id;
    return chatController.getMessages(req, res);
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get messages'
    });
  }
});

// Send message
router.post('/conversations/:id/messages', authenticate, async (req, res) => {
  try {
    // Redirect to new endpoint
    req.params.conversationId = req.params.id;
    return chatController.sendMessage(req, res);
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send message'
    });
  }
});

module.exports = router;