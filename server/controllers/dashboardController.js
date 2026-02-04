const Booking = require('../models/Booking');
const Review = require('../models/Review');
const TutorProfile = require('../models/TutorProfile');
const Notification = require('../models/Notification');

// Get student dashboard data
exports.getStudentDashboard = async (req, res) => {
  try {
    const studentId = req.user.userId;
    const now = new Date();

    // Get upcoming sessions (confirmed bookings in the future)
    const upcomingSessions = await Booking.find({
      studentId,
      status: { $in: ['confirmed', 'pending'] },
      sessionDate: { $gte: now }
    })
      .populate('tutorId', 'firstName lastName profilePicture')
      .populate('tutorProfileId', 'bio subjects pricing')
      .sort({ sessionDate: 1, startTime: 1 })
      .limit(5);

    // Format upcoming sessions
    const formattedUpcoming = upcomingSessions.map(booking => ({
      id: booking._id,
      tutorId: booking.tutorId?._id,
      tutorName: booking.tutorId ? `${booking.tutorId.firstName} ${booking.tutorId.lastName}` : 'Tutor',
      tutorPhoto: booking.tutorId?.profilePicture,
      subject: booking.subject?.name || 'Session',
      sessionDate: booking.sessionDate,
      startTime: booking.startTime,
      endTime: booking.endTime,
      duration: booking.duration,
      sessionType: booking.sessionType,
      status: booking.status,
      totalAmount: booking.totalAmount,
      location: booking.location,
      canStart: booking.canStartSession()
    }));

    // Get recent activity (last 10 bookings and notifications)
    const recentBookings = await Booking.find({
      studentId
    })
      .populate('tutorId', 'firstName lastName')
      .sort({ createdAt: -1 })
      .limit(10);

    const recentNotifications = await Notification.find({
      userId: studentId
    })
      .sort({ createdAt: -1 })
      .limit(5);

    // Combine and format recent activity
    const activities = [];

    // Add booking activities
    for (const booking of recentBookings) {
      const tutorName = booking.tutorId ? `${booking.tutorId.firstName} ${booking.tutorId.lastName}` : 'Tutor';
      
      if (booking.status === 'confirmed') {
        activities.push({
          type: 'booking_confirmed',
          message: `Booking confirmed with ${tutorName}`,
          time: booking.respondedAt || booking.updatedAt,
          icon: 'check_circle',
          color: 'green',
          bookingId: booking._id
        });
      } else if (booking.status === 'completed') {
        activities.push({
          type: 'session_completed',
          message: `Session completed with ${tutorName}`,
          time: booking.completedAt,
          icon: 'done_all',
          color: 'teal',
          bookingId: booking._id
        });
      } else if (booking.status === 'cancelled') {
        activities.push({
          type: 'booking_cancelled',
          message: `Booking cancelled with ${tutorName}`,
          time: booking.cancelledAt,
          icon: 'cancel',
          color: 'red',
          bookingId: booking._id
        });
      } else if (booking.status === 'pending') {
        activities.push({
          type: 'booking_pending',
          message: `Booking request sent to ${tutorName}`,
          time: booking.createdAt,
          icon: 'schedule',
          color: 'orange',
          bookingId: booking._id
        });
      }
    }

    // Add notification activities
    for (const notif of recentNotifications) {
      activities.push({
        type: 'notification',
        message: notif.title,
        time: notif.createdAt,
        icon: 'notifications',
        color: 'blue',
        notificationId: notif._id
      });
    }

    // Sort by time (most recent first)
    activities.sort((a, b) => new Date(b.time) - new Date(a.time));

    // Get stats
    const totalBookings = await Booking.countDocuments({ studentId });
    const completedSessions = await Booking.countDocuments({ 
      studentId, 
      status: 'completed' 
    });
    const upcomingCount = await Booking.countDocuments({
      studentId,
      status: { $in: ['confirmed', 'pending'] },
      sessionDate: { $gte: now }
    });

    res.json({
      success: true,
      data: {
        upcomingSessions: formattedUpcoming,
        recentActivity: activities.slice(0, 10),
        stats: {
          totalBookings,
          completedSessions,
          upcomingCount
        }
      }
    });
  } catch (error) {
    console.error('Get student dashboard error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to load dashboard data',
      error: error.message
    });
  }
};

// Get tutor dashboard data
exports.getTutorDashboard = async (req, res) => {
  try {
    const tutorId = req.user.userId;
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    // Get tutor profile for stats
    const tutorProfile = await TutorProfile.findOne({ userId: tutorId });
    if (!tutorProfile) {
      return res.status(404).json({
        success: false,
        message: 'Tutor profile not found'
      });
    }

    // Get upcoming sessions (confirmed bookings in the future)
    const upcomingSessions = await Booking.find({
      tutorId,
      status: { $in: ['confirmed', 'pending'] },
      sessionDate: { $gte: now }
    })
      .populate('studentId', 'firstName lastName profilePicture')
      .sort({ sessionDate: 1, startTime: 1 })
      .limit(5);

    // Format upcoming sessions
    const formattedUpcoming = upcomingSessions.map(booking => ({
      id: booking._id,
      studentId: booking.studentId?._id,
      studentName: booking.studentId ? `${booking.studentId.firstName} ${booking.studentId.lastName}` : booking.studentInfo?.name || 'Student',
      studentPhoto: booking.studentId?.profilePicture,
      subject: booking.subject?.name || 'Session',
      sessionDate: booking.sessionDate,
      startTime: booking.startTime,
      endTime: booking.endTime,
      duration: booking.duration,
      sessionType: booking.sessionType,
      status: booking.status,
      totalAmount: booking.totalAmount,
      tutorEarnings: booking.tutorEarnings,
      location: booking.location,
      canStart: booking.canStartSession()
    }));

    // Get recent activity
    const recentBookings = await Booking.find({
      tutorId
    })
      .populate('studentId', 'firstName lastName')
      .sort({ createdAt: -1 })
      .limit(10);

    const recentNotifications = await Notification.find({
      userId: tutorId
    })
      .sort({ createdAt: -1 })
      .limit(5);

    // Combine and format recent activity
    const activities = [];

    // Add booking activities
    for (const booking of recentBookings) {
      const studentName = booking.studentId ? `${booking.studentId.firstName} ${booking.studentId.lastName}` : booking.studentInfo?.name || 'Student';
      
      if (booking.status === 'pending') {
        activities.push({
          type: 'booking_request',
          message: `New booking request from ${studentName}`,
          time: booking.createdAt,
          icon: 'book_online',
          color: 'blue',
          bookingId: booking._id
        });
      } else if (booking.status === 'confirmed') {
        activities.push({
          type: 'booking_confirmed',
          message: `Booking confirmed with ${studentName}`,
          time: booking.respondedAt || booking.updatedAt,
          icon: 'check_circle',
          color: 'green',
          bookingId: booking._id
        });
      } else if (booking.status === 'completed') {
        activities.push({
          type: 'session_completed',
          message: `Session completed with ${studentName}`,
          time: booking.completedAt,
          icon: 'done_all',
          color: 'teal',
          bookingId: booking._id
        });
      } else if (booking.status === 'cancelled') {
        activities.push({
          type: 'booking_cancelled',
          message: `Booking cancelled by ${studentName}`,
          time: booking.cancelledAt,
          icon: 'cancel',
          color: 'red',
          bookingId: booking._id
        });
      }
    }

    // Add notification activities
    for (const notif of recentNotifications) {
      activities.push({
        type: 'notification',
        message: notif.title,
        time: notif.createdAt,
        icon: 'notifications',
        color: 'blue',
        notificationId: notif._id
      });
    }

    // Sort by time (most recent first)
    activities.sort((a, b) => new Date(b.time) - new Date(a.time));

    // Calculate stats
    const todaysSessions = await Booking.countDocuments({
      tutorId,
      sessionDate: { $gte: today, $lt: new Date(today.getTime() + 24 * 60 * 60 * 1000) },
      status: 'confirmed'
    });

    const thisMonthBookings = await Booking.find({
      tutorId,
      sessionDate: { $gte: firstDayOfMonth },
      status: 'completed'
    });

    const thisMonthEarnings = thisMonthBookings.reduce((sum, booking) => {
      return sum + (booking.tutorEarnings || 0);
    }, 0);

    // Get rating from reviews
    const reviews = await Review.find({ tutorId: tutorProfile._id });
    const totalReviews = reviews.length;
    const averageRating = totalReviews > 0
      ? reviews.reduce((sum, review) => sum + review.rating, 0) / totalReviews
      : 0;

    // Get unique students
    const allBookings = await Booking.find({ tutorId, status: 'completed' });
    const uniqueStudents = new Set(allBookings.map(b => b.studentId?.toString()).filter(Boolean));

    res.json({
      success: true,
      data: {
        upcomingSessions: formattedUpcoming,
        recentActivity: activities.slice(0, 10),
        stats: {
          todaysSessions,
          thisMonthEarnings,
          rating: averageRating,
          totalReviews,
          totalStudents: uniqueStudents.size,
          completedSessions: allBookings.length,
          pendingRequests: await Booking.countDocuments({ tutorId, status: 'pending' })
        }
      }
    });
  } catch (error) {
    console.error('Get tutor dashboard error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to load dashboard data',
      error: error.message
    });
  }
};

module.exports = exports;
