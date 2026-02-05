const jwt = require('jsonwebtoken');
const User = require('../models/User');

class SocketHandler {
  constructor(io) {
    this.io = io;
    this.connectedUsers = new Map(); // userId -> socketId
    this.userSockets = new Map(); // socketId -> userId
    
    this.setupSocketAuth();
    this.setupEventHandlers();
  }

  setupSocketAuth() {
    this.io.use(async (socket, next) => {
      try {
        const token = socket.handshake.auth.token;
        if (!token) {
          return next(new Error('Authentication error: No token provided'));
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.userId);
        
        if (!user || !user.isActive) {
          return next(new Error('Authentication error: Invalid user'));
        }

        socket.userId = user._id.toString();
        socket.userRole = user.role;
        socket.userName = `${user.firstName} ${user.lastName}`;
        
        next();
      } catch (error) {
        next(new Error('Authentication error: Invalid token'));
      }
    });
  }

  setupEventHandlers() {
    this.io.on('connection', (socket) => {
      console.log(`🔌 User connected: ${socket.userName} (${socket.userId})`);
      
      // Store user connection
      this.connectedUsers.set(socket.userId, socket.id);
      this.userSockets.set(socket.id, socket.userId);
      
      // Join user to their personal room
      socket.join(`user_${socket.userId}`);
      
      // Join role-based rooms
      socket.join(`role_${socket.userRole}`);
      
      // Notify user is online
      this.broadcastUserStatus(socket.userId, 'online');
      
      // Handle chat events
      this.setupChatHandlers(socket);
      
      // Handle booking events
      this.setupBookingHandlers(socket);
      
      // Handle notification events
      this.setupNotificationHandlers(socket);
      
      // Handle disconnect
      socket.on('disconnect', () => {
        console.log(`🔌 User disconnected: ${socket.userName} (${socket.userId})`);
        
        this.connectedUsers.delete(socket.userId);
        this.userSockets.delete(socket.id);
        
        // Notify user is offline
        this.broadcastUserStatus(socket.userId, 'offline');
        
        // ✅ Remove all listeners to prevent "cannot add new event" errors
        socket.removeAllListeners();
      });
    });
  }

  setupChatHandlers(socket) {
    // Join chat room
    socket.on('join_chat', (data) => {
      const { chatId } = data;
      socket.join(`chat_${chatId}`);
      console.log(`💬 User ${socket.userName} joined chat ${chatId}`);
    });

    // Leave chat room
    socket.on('leave_chat', (data) => {
      const { chatId } = data;
      socket.leave(`chat_${chatId}`);
      console.log(`💬 User ${socket.userName} left chat ${chatId}`);
    });

    // Send message
    socket.on('send_message', async (data) => {
      try {
        const { chatId, message, recipientId } = data;
        
        // Save message to database (you'll need to implement this)
        const messageData = {
          chatId,
          senderId: socket.userId,
          senderName: socket.userName,
          message,
          timestamp: new Date(),
          type: 'text'
        };

        // Broadcast to chat room
        this.io.to(`chat_${chatId}`).emit('new_message', messageData);
        
        // Send push notification to recipient if offline
        if (recipientId && !this.connectedUsers.has(recipientId)) {
          this.sendPushNotification(recipientId, {
            title: `New message from ${socket.userName}`,
            body: message,
            type: 'chat',
            data: { chatId, senderId: socket.userId }
          });
        }
        
        console.log(`💬 Message sent in chat ${chatId} by ${socket.userName}`);
      } catch (error) {
        console.error('Error sending message:', error);
        socket.emit('message_error', { error: 'Failed to send message' });
      }
    });

    // Typing indicators
    socket.on('typing_start', (data) => {
      const { chatId } = data;
      socket.to(`chat_${chatId}`).emit('user_typing', {
        userId: socket.userId,
        userName: socket.userName
      });
    });

    socket.on('typing_stop', (data) => {
      const { chatId } = data;
      socket.to(`chat_${chatId}`).emit('user_stopped_typing', {
        userId: socket.userId
      });
    });
  }

  setupBookingHandlers(socket) {
    // New booking request from student
    socket.on('booking_request', async (data) => {
      try {
        console.log('📅 New booking request:', data);
        
        const bookingController = require('../controllers/bookingController');
        
        // Create booking request in database
        const mockReq = {
          body: data,
          user: { userId: socket.userId }
        };
        
        const mockRes = {
          status: (code) => ({
            json: (response) => {
              if (response.success) {
                // Notify tutor about new booking request
                this.io.to(`user_${data.tutorId}`).emit('new_booking_request', {
                  ...data,
                  requestId: response.data.id,
                  studentName: data.studentName,
                  timestamp: new Date().toISOString()
                });
                
                // Confirm to student
                socket.emit('booking_request_sent', {
                  success: true,
                  message: 'Booking request sent successfully',
                  bookingId: response.data.id
                });
                
                // Send push notification if tutor is offline
                if (!this.connectedUsers.has(data.tutorId)) {
                  this.sendPushNotification(data.tutorId, {
                    title: 'New Booking Request',
                    body: `${data.studentName} wants to book a session with you`,
                    type: 'booking_request',
                    data: { studentId: socket.userId, bookingData: data }
                  });
                }
              } else {
                socket.emit('booking_request_error', {
                  success: false,
                  message: response.message
                });
              }
            }
          }),
          json: (response) => {
            if (response.success) {
              // Notify tutor about new booking request
              this.io.to(`user_${data.tutorId}`).emit('new_booking_request', {
                ...data,
                requestId: response.data.id,
                studentName: data.studentName,
                timestamp: new Date().toISOString()
              });
              
              // Confirm to student
              socket.emit('booking_request_sent', {
                success: true,
                message: 'Booking request sent successfully',
                bookingId: response.data.id
              });
            }
          }
        };
        
        await bookingController.createBookingRequest(mockReq, mockRes);
        
      } catch (error) {
        console.error('❌ Error processing booking request:', error);
        socket.emit('booking_request_error', {
          success: false,
          message: 'Failed to process booking request'
        });
      }
    });

    // Booking response from tutor (accept/decline)
    socket.on('booking_response', async (data) => {
      try {
        console.log('📋 Booking response:', data);
        
        const { requestId, response, reason, studentId } = data;
        
        // Notify student about booking response
        this.io.to(`user_${studentId}`).emit('booking_response_received', {
          requestId,
          response,
          reason,
          tutorId: socket.userId,
          tutorName: socket.userName,
          timestamp: new Date().toISOString()
        });
        
        // Confirm to tutor
        socket.emit('booking_response_sent', {
          requestId,
          response,
          timestamp: new Date().toISOString()
        });
        
        // Send push notification if student is offline
        if (!this.connectedUsers.has(studentId)) {
          const title = response === 'accepted' ? 'Booking Confirmed!' : 'Booking Declined';
          const body = response === 'accepted' 
            ? `${socket.userName} accepted your booking request`
            : `${socket.userName} declined your booking request`;
            
          this.sendPushNotification(studentId, {
            title,
            body,
            type: 'booking_response',
            data: { tutorId: socket.userId, requestId, response }
          });
        }
        
        console.log(`📅 Booking ${response} by ${socket.userName} for request ${requestId}`);
      } catch (error) {
        console.error('Error handling booking response:', error);
        socket.emit('booking_error', { error: 'Failed to send booking response' });
      }
    });

    // Session updates
    socket.on('session_update', (data) => {
      console.log('🎓 Session update:', data);
      
      const { type, sessionId, tutorId, studentId, message } = data;
      
      // Emit to both tutor and student
      if (tutorId && tutorId !== socket.userId) {
        this.io.to(`user_${tutorId}`).emit('session_updated', {
          type,
          sessionId,
          message,
          timestamp: new Date().toISOString()
        });
      }
      
      if (studentId && studentId !== socket.userId) {
        this.io.to(`user_${studentId}`).emit('session_updated', {
          type,
          sessionId,
          message,
          timestamp: new Date().toISOString()
        });
      }
    });

    // Session completion
    socket.on('session_completed', (data) => {
      console.log('✅ Session completed:', data);
      
      const { slotId, notes, studentId } = data;
      
      // Notify student
      if (studentId) {
        this.io.to(`user_${studentId}`).emit('session_completed', {
          slotId,
          notes,
          tutorId: socket.userId,
          tutorName: socket.userName,
          timestamp: new Date().toISOString()
        });
      }
    });

    // Session cancellation
    socket.on('session_cancelled', (data) => {
      console.log('❌ Session cancelled:', data);
      
      const { slotId, reason, studentId } = data;
      
      // Notify student
      if (studentId) {
        this.io.to(`user_${studentId}`).emit('session_cancelled', {
          slotId,
          reason,
          tutorId: socket.userId,
          tutorName: socket.userName,
          timestamp: new Date().toISOString()
        });
      }
    });

    // Session reminders
    socket.on('session_reminder', (data) => {
      const { participantId, sessionData } = data;
      
      this.io.to(`user_${participantId}`).emit('session_reminder', {
        sessionData,
        timestamp: new Date()
      });
    });

    // Reschedule request
    socket.on('reschedule_request', (data) => {
      console.log('📅 Reschedule request:', data);
      
      const { bookingId, newDate, newTime, reason, recipientId } = data;
      
      this.io.to(`user_${recipientId}`).emit('reschedule_requested', {
        bookingId,
        newDate,
        newTime,
        reason,
        requestedBy: socket.userId,
        requestedByName: socket.userName,
        timestamp: new Date()
      });

      if (!this.connectedUsers.has(recipientId)) {
        this.sendPushNotification(recipientId, {
          title: 'Reschedule Request',
          body: `${socket.userName} wants to reschedule your session`,
          type: 'reschedule_request',
          data: { bookingId, newDate, newTime }
        });
      }
    });

    // Reschedule response
    socket.on('reschedule_response', (data) => {
      console.log('📅 Reschedule response:', data);
      
      const { bookingId, response, recipientId } = data;
      
      this.io.to(`user_${recipientId}`).emit('reschedule_responded', {
        bookingId,
        response,
        respondedBy: socket.userId,
        respondedByName: socket.userName,
        timestamp: new Date()
      });
    });

    // Payment completed
    socket.on('payment_completed', (data) => {
      console.log('💳 Payment completed:', data);
      
      const { bookingId, tutorId, amount } = data;
      
      this.io.to(`user_${tutorId}`).emit('payment_received', {
        bookingId,
        amount,
        studentId: socket.userId,
        studentName: socket.userName,
        timestamp: new Date()
      });
    });

    // Refund processed
    socket.on('refund_processed', (data) => {
      console.log('💰 Refund processed:', data);
      
      const { bookingId, studentId, amount } = data;
      
      this.io.to(`user_${studentId}`).emit('refund_received', {
        bookingId,
        amount,
        timestamp: new Date()
      });
    });

    // Dispute created
    socket.on('dispute_created', (data) => {
      console.log('⚠️ Dispute created:', data);
      
      const { bookingId, reason, recipientId } = data;
      
      this.io.to(`user_${recipientId}`).emit('dispute_notification', {
        bookingId,
        reason,
        createdBy: socket.userId,
        createdByName: socket.userName,
        timestamp: new Date()
      });

      // Notify admins
      this.broadcastToRole('admin', 'new_dispute', {
        bookingId,
        reason,
        createdBy: socket.userId,
        createdByName: socket.userName,
        timestamp: new Date()
      });
    });

    // Rating added
    socket.on('rating_added', (data) => {
      console.log('⭐ Rating added:', data);
      
      const { bookingId, rating, review, recipientId } = data;
      
      this.io.to(`user_${recipientId}`).emit('rating_received', {
        bookingId,
        rating,
        review,
        ratedBy: socket.userId,
        ratedByName: socket.userName,
        timestamp: new Date()
      });
    });
  }

  setupNotificationHandlers(socket) {
    // Mark notification as read
    socket.on('mark_notification_read', (data) => {
      const { notificationId } = data;
      // Update notification status in database
      console.log(`🔔 Notification ${notificationId} marked as read by ${socket.userName}`);
    });

    // Get unread notification count
    socket.on('get_unread_count', async () => {
      try {
        // Get unread count from database
        const unreadCount = 0; // Implement this
        socket.emit('unread_count', { count: unreadCount });
      } catch (error) {
        console.error('Error getting unread count:', error);
      }
    });
  }

  // Utility methods
  broadcastUserStatus(userId, status) {
    try {
      if (this.io && this.io.sockets) {
        this.io.emit('user_status_change', {
          userId,
          status,
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('⚠️ Error broadcasting user status:', error.message);
    }
  }

  sendNotificationToUser(userId, notification) {
    try {
      const socketId = this.connectedUsers.get(userId);
      if (socketId && this.io && this.io.sockets) {
        const socket = this.io.sockets.sockets.get(socketId);
        if (socket && socket.connected) {
          socket.emit('notification', notification);
        } else {
          // Socket not connected, send push notification
          this.sendPushNotification(userId, notification);
        }
      } else {
        // Send push notification if user is offline
        this.sendPushNotification(userId, notification);
      }
    } catch (error) {
      console.error('⚠️ Error sending notification to user:', error.message);
      // Fallback to push notification
      this.sendPushNotification(userId, notification);
    }
  }

  sendPushNotification(userId, notification) {
    // Implement push notification logic here
    // This could integrate with Firebase Cloud Messaging, Apple Push Notifications, etc.
    console.log(`📱 Push notification sent to user ${userId}:`, notification);
  }

  broadcastToRole(role, event, data) {
    try {
      if (this.io && this.io.sockets) {
        this.io.to(`role_${role}`).emit(event, data);
      }
    } catch (error) {
      console.error('⚠️ Error broadcasting to role:', error.message);
    }
  }

  getConnectedUsers() {
    return Array.from(this.connectedUsers.keys());
  }

  isUserOnline(userId) {
    return this.connectedUsers.has(userId);
  }
}

module.exports = SocketHandler;