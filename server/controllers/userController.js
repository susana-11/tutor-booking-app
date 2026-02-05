const User = require('../models/User');

// Get notification preferences
exports.getNotificationPreferences = async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Return preferences or defaults
    const preferences = user.notificationPreferences || {
      emailNotifications: true,
      pushNotifications: true,
      bookingNotifications: true,
      messageNotifications: true,
      reviewNotifications: true,
      paymentNotifications: true,
      reminderNotifications: true,
      promotionalNotifications: false
    };

    res.json({
      success: true,
      data: preferences
    });

  } catch (error) {
    console.error('Get notification preferences error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get notification preferences',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Update notification preferences
exports.updateNotificationPreferences = async (req, res) => {
  try {
    const {
      emailNotifications,
      pushNotifications,
      bookingNotifications,
      messageNotifications,
      reviewNotifications,
      paymentNotifications,
      reminderNotifications,
      promotionalNotifications
    } = req.body;

    const user = await User.findById(req.user.userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Update preferences
    user.notificationPreferences = {
      emailNotifications: emailNotifications !== undefined ? emailNotifications : true,
      pushNotifications: pushNotifications !== undefined ? pushNotifications : true,
      bookingNotifications: bookingNotifications !== undefined ? bookingNotifications : true,
      messageNotifications: messageNotifications !== undefined ? messageNotifications : true,
      reviewNotifications: reviewNotifications !== undefined ? reviewNotifications : true,
      paymentNotifications: paymentNotifications !== undefined ? paymentNotifications : true,
      reminderNotifications: reminderNotifications !== undefined ? reminderNotifications : true,
      promotionalNotifications: promotionalNotifications !== undefined ? promotionalNotifications : false
    };

    await user.save();

    res.json({
      success: true,
      message: 'Notification preferences updated successfully',
      data: user.notificationPreferences
    });

  } catch (error) {
    console.error('Update notification preferences error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update notification preferences',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};
