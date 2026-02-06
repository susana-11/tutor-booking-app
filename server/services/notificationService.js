const Notification = require('../models/Notification');
const DeviceToken = require('../models/DeviceToken');
const User = require('../models/User');

// Firebase Admin will be initialized if credentials are provided
let admin = null;
let firebaseInitialized = false;

try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    admin = require('firebase-admin');
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    firebaseInitialized = true;
    console.log('✅ Firebase Admin initialized');
  } else {
    console.log('⚠️  Firebase credentials not found. Push notifications disabled.');
  }
} catch (error) {
  console.error('❌ Firebase initialization error:', error.message);
}

class NotificationService {
  
  // Create and save notification
  async createNotification({ userId, type, title, body, data = {}, priority = 'normal', actionUrl, imageUrl }) {
    try {
      console.log('📝 Creating notification:', {
        userId: userId.toString(),
        type,
        title,
        priority
      });

      const notification = new Notification({
        userId,
        type,
        title,
        body,
        data,
        priority,
        actionUrl,
        imageUrl
      });

      await notification.save();
      console.log('✅ Notification saved to database:', notification._id.toString());
      
      // Send push notification
      await this.sendPushNotification(userId, { title, body, data, priority });
      
      // Send real-time notification via Socket.IO
      const io = global.io;
      if (io) {
        io.to(`user_${userId}`).emit('notification', {
          id: notification._id,
          type,
          title,
          body,
          data,
          priority,
          createdAt: notification.createdAt
        });
        console.log('✅ Real-time notification emitted via Socket.IO');
      } else {
        console.log('⚠️  Socket.IO not available for real-time notification');
      }

      return notification;
    } catch (error) {
      console.error('❌ Create notification error:', error);
      throw error;
    }
  }

  // Send push notification via FCM
  async sendPushNotification(userId, { title, body, data = {}, priority = 'normal' }) {
    if (!firebaseInitialized || !admin) {
      console.log('Push notification skipped - Firebase not initialized');
      return;
    }

    try {
      // Get user's device tokens
      const tokens = await DeviceToken.find({ userId, isActive: true });
      
      if (tokens.length === 0) {
        console.log(`No active device tokens for user ${userId}`);
        return;
      }

      const fcmTokens = tokens.map(t => t.token);

      // Prepare FCM message
      const message = {
        notification: {
          title,
          body
        },
        data: {
          ...Object.keys(data).reduce((acc, key) => {
            acc[key] = String(data[key]);
            return acc;
          }, {}),
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
        android: {
          priority: priority === 'urgent' || priority === 'high' ? 'high' : 'normal',
          notification: {
            sound: 'default',
            channelId: 'default'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        },
        tokens: fcmTokens
      };

      // Send to multiple devices
      const response = await admin.messaging().sendMulticast(message);
      
      console.log(`✅ Push notification sent: ${response.successCount}/${fcmTokens.length} successful`);

      // Handle failed tokens
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(fcmTokens[idx]);
          }
        });
        
        // Deactivate failed tokens
        await DeviceToken.updateMany(
          { token: { $in: failedTokens } },
          { isActive: false }
        );
      }

      return response;
    } catch (error) {
      console.error('Send push notification error:', error);
    }
  }

  // Booking notifications
  async notifyBookingRequest({ tutorId, studentName, subject, date, time, bookingId }) {
    return this.createNotification({
      userId: tutorId,
      type: 'booking_request',
      title: 'New Booking Request',
      body: `${studentName} wants to book a ${subject} session on ${date} at ${time}`,
      data: { type: 'booking_request', bookingId },
      priority: 'high',
      actionUrl: '/tutor/bookings'
    });
  }

  async notifyBookingAccepted({ studentId, tutorName, subject, date, time, bookingId }) {
    return this.createNotification({
      userId: studentId,
      type: 'booking_accepted',
      title: 'Booking Confirmed! 🎉',
      body: `${tutorName} accepted your ${subject} session on ${date} at ${time}`,
      data: { type: 'booking_accepted', bookingId },
      priority: 'high',
      actionUrl: '/student/bookings'
    });
  }

  // Send booking confirmed notification (after payment)
  async sendBookingConfirmedNotification(booking) {
    try {
      const sessionDate = new Date(booking.sessionDate);
      const dateStr = sessionDate.toLocaleDateString('en-US', { 
        weekday: 'short', 
        month: 'short', 
        day: 'numeric' 
      });

      const studentName = booking.studentId?.firstName || 'Student';
      const tutorName = booking.tutorId?.firstName || 'Tutor';
      const subject = booking.subject?.name || 'session';

      // Notify student
      await this.createNotification({
        userId: booking.studentId._id || booking.studentId,
        type: 'booking_confirmed',
        title: 'Booking Confirmed! 🎉',
        body: `Your ${subject} session with ${tutorName} on ${dateStr} at ${booking.startTime} is confirmed!`,
        data: { 
          type: 'booking_confirmed', 
          bookingId: booking._id.toString() 
        },
        priority: 'high',
        actionUrl: '/student/bookings'
      });

      // Notify tutor
      await this.createNotification({
        userId: booking.tutorId._id || booking.tutorId,
        type: 'booking_confirmed',
        title: 'New Booking Confirmed! 🎉',
        body: `${studentName} booked a ${subject} session on ${dateStr} at ${booking.startTime}`,
        data: { 
          type: 'booking_confirmed', 
          bookingId: booking._id.toString() 
        },
        priority: 'high',
        actionUrl: '/tutor/bookings'
      });

      console.log(`✅ Sent booking confirmed notifications for booking ${booking._id}`);
      return true;
    } catch (error) {
      console.error('Error sending booking confirmed notification:', error);
      throw error;
    }
  }

  async notifyBookingDeclined({ studentId, tutorName, subject, reason, bookingId }) {
    return this.createNotification({
      userId: studentId,
      type: 'booking_declined',
      title: 'Booking Declined',
      body: `${tutorName} declined your ${subject} session${reason ? `: ${reason}` : ''}`,
      data: { type: 'booking_declined', bookingId },
      priority: 'normal',
      actionUrl: '/student/bookings'
    });
  }

  async notifyBookingCancelled({ userId, cancelledBy, subject, date, reason, bookingId }) {
    console.log('📧 Creating booking cancelled notification:', {
      userId: userId.toString(),
      cancelledBy,
      subject,
      date,
      bookingId: bookingId.toString()
    });

    return this.createNotification({
      userId,
      type: 'booking_cancelled',
      title: 'Booking Cancelled',
      body: `Your ${subject} session on ${date} was cancelled by ${cancelledBy}${reason ? `: ${reason}` : ''}`,
      data: { type: 'booking_cancelled', cancelledBy, bookingId: bookingId.toString() },
      priority: 'high',
      actionUrl: '/bookings'
    });
  }

  // Send booking reminder (called by reminder scheduler)
  async sendBookingReminder(booking, type) {
    try {
      // Format the reminder message based on type
      let timeMessage;
      switch (type) {
        case '24_hours':
          timeMessage = '24 hours';
          break;
        case '1_hour':
          timeMessage = '1 hour';
          break;
        case '15_minutes':
          timeMessage = '15 minutes';
          break;
        default:
          timeMessage = 'soon';
      }

      // Format date and time
      const sessionDate = new Date(booking.sessionDate);
      const dateStr = sessionDate.toLocaleDateString('en-US', { 
        weekday: 'short', 
        month: 'short', 
        day: 'numeric' 
      });

      // Get user details
      const studentName = booking.studentId?.firstName || 'Student';
      const tutorName = booking.tutorId?.firstName || 'Tutor';
      const subject = booking.subject?.name || 'session';

      // Send reminder to student
      await this.createNotification({
        userId: booking.studentId._id || booking.studentId,
        type: 'booking_reminder',
        title: 'Session Reminder ⏰',
        body: `Your ${subject} session with ${tutorName} starts in ${timeMessage} (${dateStr} at ${booking.startTime})`,
        data: { 
          type: 'booking_reminder', 
          bookingId: booking._id.toString(),
          reminderType: type 
        },
        priority: type === '15_minutes' ? 'urgent' : 'high',
        actionUrl: '/student/bookings'
      });

      // Send reminder to tutor
      await this.createNotification({
        userId: booking.tutorId._id || booking.tutorId,
        type: 'booking_reminder',
        title: 'Session Reminder ⏰',
        body: `Your ${subject} session with ${studentName} starts in ${timeMessage} (${dateStr} at ${booking.startTime})`,
        data: { 
          type: 'booking_reminder', 
          bookingId: booking._id.toString(),
          reminderType: type 
        },
        priority: type === '15_minutes' ? 'urgent' : 'high',
        actionUrl: '/tutor/bookings'
      });

      console.log(`✅ Sent ${type} reminder to both student and tutor for booking ${booking._id}`);
      return true;
    } catch (error) {
      console.error('Error sending booking reminder:', error);
      throw error;
    }
  }

  // Send rating request (called by reminder scheduler for completed sessions)
  async sendRatingRequest(booking) {
    try {
      const subject = booking.subject?.name || 'session';
      const studentName = booking.studentId?.firstName || 'Student';
      const tutorName = booking.tutorId?.firstName || 'Tutor';

      // Send rating request to student if they haven't rated yet
      if (!booking.rating?.studentRating?.score) {
        await this.createNotification({
          userId: booking.studentId._id || booking.studentId,
          type: 'rating_request',
          title: 'Rate Your Session ⭐',
          body: `How was your ${subject} session with ${tutorName}? Please rate your experience.`,
          data: { 
            type: 'rating_request', 
            bookingId: booking._id.toString() 
          },
          priority: 'normal',
          actionUrl: '/student/bookings'
        });
      }

      // Send rating request to tutor if they haven't rated yet
      if (!booking.rating?.tutorRating?.score) {
        await this.createNotification({
          userId: booking.tutorId._id || booking.tutorId,
          type: 'rating_request',
          title: 'Rate Your Session ⭐',
          body: `How was your ${subject} session with ${studentName}? Please rate your experience.`,
          data: { 
            type: 'rating_request', 
            bookingId: booking._id.toString() 
          },
          priority: 'normal',
          actionUrl: '/tutor/bookings'
        });
      }

      console.log(`✅ Sent rating request for booking ${booking._id}`);
      return true;
    } catch (error) {
      console.error('Error sending rating request:', error);
      throw error;
    }
  }

  // Message notifications
  async notifyNewMessage({ userId, senderName, message, conversationId }) {
    return this.createNotification({
      userId,
      type: 'new_message',
      title: `New message from ${senderName}`,
      body: message.substring(0, 100),
      data: { type: 'new_message', conversationId },
      priority: 'normal',
      actionUrl: '/messages'
    });
  }

  // Call notifications
  async notifyIncomingCall({ userId, callerName, callType, callId }) {
    return this.createNotification({
      userId,
      type: 'call_incoming',
      title: `Incoming ${callType} call`,
      body: `${callerName} is calling you`,
      data: { type: 'call_incoming', callType, callId },
      priority: 'urgent',
      actionUrl: '/call'
    });
  }

  async notifyMissedCall({ userId, callerName, callType, callId }) {
    return this.createNotification({
      userId,
      type: 'call_missed',
      title: 'Missed Call',
      body: `You missed a ${callType} call from ${callerName}`,
      data: { type: 'call_missed', callId },
      priority: 'normal',
      actionUrl: '/call-history'
    });
  }

  // Payment notifications
  async notifyPaymentReceived({ userId, amount, bookingId }) {
    return this.createNotification({
      userId,
      type: 'payment_received',
      title: 'Payment Received 💰',
      body: `You received $${amount} for your tutoring session`,
      data: { type: 'payment_received', bookingId },
      priority: 'normal',
      actionUrl: '/earnings'
    });
  }

  // Profile notifications
  async notifyProfileApproved({ userId }) {
    return this.createNotification({
      userId,
      type: 'profile_approved',
      title: 'Profile Approved! ✅',
      body: 'Your tutor profile has been approved. You can now start accepting bookings!',
      data: { type: 'profile_approved' },
      priority: 'high',
      actionUrl: '/profile'
    });
  }

  async notifyProfileRejected({ userId, reason }) {
    return this.createNotification({
      userId,
      type: 'profile_rejected',
      title: 'Profile Needs Updates',
      body: `Your tutor profile needs some updates: ${reason}`,
      data: { type: 'profile_rejected' },
      priority: 'high',
      actionUrl: '/profile'
    });
  }

  // System notifications
  async notifySystemAnnouncement({ userIds, title, body }) {
    const notifications = userIds.map(userId => 
      this.createNotification({
        userId,
        type: 'system_announcement',
        title,
        body,
        data: { type: 'system_announcement' },
        priority: 'normal'
      })
    );

    return Promise.all(notifications);
  }

  // Get user notifications
  async getUserNotifications(userId, { page = 1, limit = 20, unreadOnly = false }) {
    const filter = { userId };
    if (unreadOnly) {
      filter.read = false;
    }

    const notifications = await Notification.find(filter)
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip((page - 1) * limit);

    const total = await Notification.countDocuments(filter);
    const unreadCount = await Notification.countDocuments({ userId, read: false });

    return {
      notifications,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      },
      unreadCount
    };
  }

  // Get unread count
  async getUnreadCount(userId) {
    return Notification.countDocuments({ userId, read: false });
  }

  // Mark notification as read
  async markAsRead(notificationId, userId) {
    const notification = await Notification.findOne({ _id: notificationId, userId });
    if (!notification) {
      throw new Error('Notification not found');
    }
    return notification.markAsRead();
  }

  // Mark all as read
  async markAllAsRead(userId) {
    return Notification.updateMany(
      { userId, read: false },
      { read: true, readAt: new Date() }
    );
  }

  // Delete notification
  async deleteNotification(notificationId, userId) {
    console.log('🗑️ Deleting notification:', {
      notificationId,
      userId: userId.toString()
    });
    
    const result = await Notification.findOneAndDelete({ _id: notificationId, userId });
    
    if (result) {
      console.log('✅ Notification deleted successfully:', notificationId);
    } else {
      console.log('❌ Notification not found or not owned by user:', notificationId);
    }
    
    return result;
  }

  // Register device token
  async registerDeviceToken({ userId, token, platform, deviceId, deviceName, appVersion }) {
    try {
      // Check if token already exists
      let deviceToken = await DeviceToken.findOne({ token });

      if (deviceToken) {
        // Update existing token
        deviceToken.userId = userId;
        deviceToken.platform = platform;
        deviceToken.deviceId = deviceId;
        deviceToken.deviceName = deviceName;
        deviceToken.appVersion = appVersion;
        deviceToken.isActive = true;
        deviceToken.lastUsedAt = new Date();
      } else {
        // Create new token
        deviceToken = new DeviceToken({
          userId,
          token,
          platform,
          deviceId,
          deviceName,
          appVersion
        });
      }

      await deviceToken.save();
      return deviceToken;
    } catch (error) {
      console.error('Register device token error:', error);
      throw error;
    }
  }

  // Unregister device token
  async unregisterDeviceToken(token) {
    return DeviceToken.findOneAndUpdate(
      { token },
      { isActive: false }
    );
  }
}

module.exports = new NotificationService();
