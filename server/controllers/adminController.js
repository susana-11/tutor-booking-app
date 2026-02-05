const TutorProfile = require('../models/TutorProfile');
const StudentProfile = require('../models/StudentProfile');
const User = require('../models/User');

// Get all pending tutor applications
exports.getPendingTutors = async (req, res) => {
  try {
    const tutors = await TutorProfile.find({ status: 'pending' })
      .populate('userId', 'firstName lastName email phone')
      .sort({ createdAt: -1 });

    res.json(tutors);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all tutors (approved, rejected, pending)
exports.getAllTutors = async (req, res) => {
  try {
    const { status } = req.query;

    let filter = {};
    if (status) {
      filter.status = status;
    }

    const tutors = await TutorProfile.find(filter)
      .populate('userId', 'firstName lastName email phone')
      .sort({ createdAt: -1 });

    res.json(tutors);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Approve tutor
exports.approveTutor = async (req, res) => {
  try {
    const { tutorId } = req.params;

    const profile = await TutorProfile.findByIdAndUpdate(
      tutorId,
      { status: 'approved', rejectionReason: null },
      { new: true }
    ).populate('userId', 'firstName lastName email phone');

    if (!profile) {
      return res.status(404).json({ message: 'Tutor profile not found' });
    }

    res.json({
      message: 'Tutor approved successfully',
      profile,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Reject tutor
exports.rejectTutor = async (req, res) => {
  try {
    const { tutorId } = req.params;
    const { reason } = req.body;

    if (!reason) {
      return res.status(400).json({ message: 'Rejection reason is required' });
    }

    const profile = await TutorProfile.findByIdAndUpdate(
      tutorId,
      { status: 'rejected', rejectionReason: reason },
      { new: true }
    ).populate('userId', 'firstName lastName email phone');

    if (!profile) {
      return res.status(404).json({ message: 'Tutor profile not found' });
    }

    res.json({
      message: 'Tutor rejected successfully',
      profile,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all users grouped by role
exports.getAllUsers = async (req, res) => {
  try {
    const { role, page = 1, limit = 10, search } = req.query;

    let filter = {};
    if (role && role !== 'all') {
      filter.role = role;
    }

    // Add search functionality
    if (search) {
      filter.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }

    const users = await User.find(filter)
      .select('-password')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await User.countDocuments(filter);

    // Get additional profile data for each user
    const usersWithProfiles = await Promise.all(users.map(async (user) => {
      let profileData = null;
      
      if (user.role === 'tutor') {
        profileData = await TutorProfile.findOne({ userId: user._id })
          .select('status bio subjects pricing.hourlyRate stats.averageRating stats.totalSessions');
      } else if (user.role === 'student') {
        profileData = await StudentProfile.findOne({ userId: user._id })
          .select('grade interestedSubjects school');
      }

      return {
        ...user.toObject(),
        profile: profileData
      };
    }));

    res.json({
      success: true,
      data: {
        users: usersWithProfiles,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get all users error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Get users grouped by role
exports.getUsersByRole = async (req, res) => {
  try {
    const students = await User.find({ role: 'student' })
      .select('-password')
      .sort({ createdAt: -1 });

    const tutors = await User.find({ role: 'tutor' })
      .select('-password')
      .sort({ createdAt: -1 });

    // Get profile data for tutors
    const tutorsWithProfiles = await Promise.all(tutors.map(async (tutor) => {
      const profile = await TutorProfile.findOne({ userId: tutor._id })
        .select('status bio subjects pricing.hourlyRate stats.averageRating stats.totalSessions');
      
      return {
        ...tutor.toObject(),
        profile
      };
    }));

    // Get profile data for students
    const studentsWithProfiles = await Promise.all(students.map(async (student) => {
      const profile = await StudentProfile.findOne({ userId: student._id })
        .select('grade interestedSubjects school');
      
      return {
        ...student.toObject(),
        profile
      };
    }));

    res.json({
      success: true,
      data: {
        students: studentsWithProfiles,
        tutors: tutorsWithProfiles,
        stats: {
          totalStudents: students.length,
          totalTutors: tutors.length,
          activeTutors: tutorsWithProfiles.filter(t => t.profile?.status === 'approved').length,
          pendingTutors: tutorsWithProfiles.filter(t => t.profile?.status === 'pending').length
        }
      }
    });
  } catch (error) {
    console.error('Get users by role error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Delete user (soft delete by deactivating)
exports.deleteUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { permanent = false } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Prevent deleting admin users
    if (user.role === 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Cannot delete admin users'
      });
    }

    if (permanent) {
      // Permanent deletion - remove user and associated profiles
      if (user.role === 'tutor') {
        await TutorProfile.deleteOne({ userId });
      } else if (user.role === 'student') {
        await StudentProfile.deleteOne({ userId });
      }
      
      await User.findByIdAndDelete(userId);
      
      res.json({
        success: true,
        message: 'User permanently deleted'
      });
    } else {
      // Soft delete - deactivate user
      const updatedUser = await User.findByIdAndUpdate(
        userId,
        { isActive: false },
        { new: true }
      ).select('-password');

      res.json({
        success: true,
        message: 'User deactivated successfully',
        data: { user: updatedUser }
      });
    }
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Suspend user
exports.suspendUser = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findByIdAndUpdate(
      userId,
      { isActive: false },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      message: 'User suspended successfully',
      user,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Activate user
exports.activateUser = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findByIdAndUpdate(
      userId,
      { isActive: true },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      message: 'User activated successfully',
      user,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get dashboard stats
exports.getDashboardStats = async (req, res) => {
  try {
    const Booking = require('../models/Booking');
    const Transaction = require('../models/Transaction');
    const Subject = require('../models/Subject');

    // User stats
    const totalUsers = await User.countDocuments();
    const totalStudents = await User.countDocuments({ role: 'student' });
    const totalTutors = await User.countDocuments({ role: 'tutor' });
    const activeUsers = await User.countDocuments({ isActive: true });
    const newUsersThisMonth = await User.countDocuments({
      createdAt: { $gte: new Date(new Date().setDate(1)) }
    });

    // Tutor stats
    const pendingTutors = await TutorProfile.countDocuments({ status: 'pending' });
    const approvedTutors = await TutorProfile.countDocuments({ status: 'approved' });
    const rejectedTutors = await TutorProfile.countDocuments({ status: 'rejected' });

    // Booking stats
    const totalBookings = await Booking.countDocuments();
    const pendingBookings = await Booking.countDocuments({ status: 'pending' });
    const confirmedBookings = await Booking.countDocuments({ status: 'confirmed' });
    const completedBookings = await Booking.countDocuments({ status: 'completed' });
    const cancelledBookings = await Booking.countDocuments({ status: 'cancelled' });
    const bookingsThisMonth = await Booking.countDocuments({
      createdAt: { $gte: new Date(new Date().setDate(1)) }
    });

    // Revenue stats
    const revenueData = await Booking.aggregate([
      { $match: { status: 'completed', paymentStatus: 'paid' } },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: '$totalAmount' },
          platformRevenue: { $sum: '$platformFee' },
          tutorEarnings: { $sum: '$tutorEarnings' }
        }
      }
    ]);

    const revenue = revenueData[0] || {
      totalRevenue: 0,
      platformRevenue: 0,
      tutorEarnings: 0
    };

    // Monthly revenue
    const monthlyRevenue = await Booking.aggregate([
      {
        $match: {
          status: 'completed',
          paymentStatus: 'paid',
          createdAt: { $gte: new Date(new Date().setDate(1)) }
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$totalAmount' },
          platformFee: { $sum: '$platformFee' }
        }
      }
    ]);

    const thisMonthRevenue = monthlyRevenue[0] || { total: 0, platformFee: 0 };

    // Subject stats
    const totalSubjects = await Subject.countDocuments();
    const activeSubjects = await Subject.countDocuments({ isActive: true });

    // Recent activity
    const recentBookings = await Booking.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .populate('studentId', 'firstName lastName')
      .populate('tutorId', 'firstName lastName')
      .select('status sessionDate startTime subject.name totalAmount createdAt');

    const recentUsers = await User.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .select('firstName lastName email role createdAt');

    res.json({
      success: true,
      data: {
        users: {
          total: totalUsers,
          students: totalStudents,
          tutors: totalTutors,
          active: activeUsers,
          newThisMonth: newUsersThisMonth
        },
        tutors: {
          pending: pendingTutors,
          approved: approvedTutors,
          rejected: rejectedTutors,
          total: pendingTutors + approvedTutors + rejectedTutors
        },
        bookings: {
          total: totalBookings,
          pending: pendingBookings,
          confirmed: confirmedBookings,
          completed: completedBookings,
          cancelled: cancelledBookings,
          thisMonth: bookingsThisMonth
        },
        revenue: {
          total: revenue.totalRevenue,
          platform: revenue.platformRevenue,
          tutors: revenue.tutorEarnings,
          thisMonth: thisMonthRevenue.total,
          platformThisMonth: thisMonthRevenue.platformFee
        },
        subjects: {
          total: totalSubjects,
          active: activeSubjects
        },
        recentActivity: {
          bookings: recentBookings,
          users: recentUsers
        }
      }
    });
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Get all bookings with filters
exports.getAllBookings = async (req, res) => {
  try {
    const Booking = require('../models/Booking');
    const { status, page = 1, limit = 20, search } = req.query;

    let filter = {};
    if (status && status !== 'all') {
      filter.status = status;
    }

    const bookings = await Booking.find(filter)
      .populate('studentId', 'firstName lastName email phone')
      .populate('tutorId', 'firstName lastName email phone')
      .populate('tutorProfileId', 'bio subjects')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Booking.countDocuments(filter);

    res.json({
      success: true,
      data: {
        bookings,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get all bookings error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Get all transactions
exports.getAllTransactions = async (req, res) => {
  try {
    const Transaction = require('../models/Transaction');
    const { type, status, page = 1, limit = 20 } = req.query;

    let filter = {};
    if (type && type !== 'all') filter.type = type;
    if (status && status !== 'all') filter.status = status;

    const transactions = await Transaction.find(filter)
      .populate('userId', 'firstName lastName email')
      .populate('bookingId', 'sessionDate subject.name')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Transaction.countDocuments(filter);

    // Calculate totals
    const totals = await Transaction.aggregate([
      { $match: filter },
      {
        $group: {
          _id: null,
          totalAmount: { $sum: '$amount' },
          totalNet: { $sum: '$netAmount' }
        }
      }
    ]);

    res.json({
      success: true,
      data: {
        transactions,
        totals: totals[0] || { totalAmount: 0, totalNet: 0 },
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get all transactions error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Get analytics data
exports.getAnalytics = async (req, res) => {
  try {
    const Booking = require('../models/Booking');
    const { period = '30' } = req.query; // days

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(period));

    // Bookings over time
    const bookingsOverTime = await Booking.aggregate([
      { $match: { createdAt: { $gte: startDate } } },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          count: { $sum: 1 },
          revenue: { $sum: '$totalAmount' }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    // Revenue by status
    const revenueByStatus = await Booking.aggregate([
      { $match: { createdAt: { $gte: startDate } } },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          revenue: { $sum: '$totalAmount' }
        }
      }
    ]);

    // Top subjects
    const topSubjects = await Booking.aggregate([
      { $match: { createdAt: { $gte: startDate }, status: 'completed' } },
      {
        $group: {
          _id: '$subject.name',
          count: { $sum: 1 },
          revenue: { $sum: '$totalAmount' }
        }
      },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);

    // Top tutors
    const topTutors = await Booking.aggregate([
      { $match: { createdAt: { $gte: startDate }, status: 'completed' } },
      {
        $group: {
          _id: '$tutorId',
          sessions: { $sum: 1 },
          earnings: { $sum: '$tutorEarnings' },
          revenue: { $sum: '$totalAmount' }
        }
      },
      { $sort: { sessions: -1 } },
      { $limit: 10 }
    ]);

    // Populate tutor details
    const populatedTopTutors = await User.populate(topTutors, {
      path: '_id',
      select: 'firstName lastName email'
    });

    // User growth
    const userGrowth = await User.aggregate([
      { $match: { createdAt: { $gte: startDate } } },
      {
        $group: {
          _id: {
            date: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            role: '$role'
          },
          count: { $sum: 1 }
        }
      },
      { $sort: { '_id.date': 1 } }
    ]);

    res.json({
      success: true,
      data: {
        bookingsOverTime,
        revenueByStatus,
        topSubjects,
        topTutors: populatedTopTutors,
        userGrowth,
        period: parseInt(period)
      }
    });
  } catch (error) {
    console.error('Get analytics error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Get all disputes
exports.getAllDisputes = async (req, res) => {
  try {
    const Dispute = require('../models/Dispute');
    const { status, priority, page = 1, limit = 20 } = req.query;

    let filter = {};
    if (status && status !== 'all') filter.status = status;
    if (priority && priority !== 'all') filter.priority = priority;

    const disputes = await Dispute.find(filter)
      .populate('studentId', 'firstName lastName email phone')
      .populate('tutorId', 'firstName lastName email phone')
      .populate('bookingId', 'sessionDate subject.name totalAmount')
      .populate('messages.sender', 'firstName lastName')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Dispute.countDocuments(filter);

    res.json({
      success: true,
      data: {
        disputes,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get all disputes error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Get dispute by ID
exports.getDisputeById = async (req, res) => {
  try {
    const Dispute = require('../models/Dispute');
    const { disputeId } = req.params;

    const dispute = await Dispute.findById(disputeId)
      .populate('studentId', 'firstName lastName email phone')
      .populate('tutorId', 'firstName lastName email phone')
      .populate('bookingId', 'sessionDate subject.name totalAmount')
      .populate('messages.sender', 'firstName lastName')
      .populate('resolvedBy', 'firstName lastName');

    if (!dispute) {
      return res.status(404).json({
        success: false,
        message: 'Dispute not found'
      });
    }

    res.json({
      success: true,
      data: { dispute }
    });
  } catch (error) {
    console.error('Get dispute error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Update dispute status
exports.updateDisputeStatus = async (req, res) => {
  try {
    const Dispute = require('../models/Dispute');
    const { disputeId } = req.params;
    const { status, priority } = req.body;

    const updateData = {};
    if (status) updateData.status = status;
    if (priority) updateData.priority = priority;

    const dispute = await Dispute.findByIdAndUpdate(
      disputeId,
      updateData,
      { new: true }
    ).populate('studentId', 'firstName lastName email')
     .populate('tutorId', 'firstName lastName email')
     .populate('bookingId', 'sessionDate subject.name');

    if (!dispute) {
      return res.status(404).json({
        success: false,
        message: 'Dispute not found'
      });
    }

    res.json({
      success: true,
      message: 'Dispute updated successfully',
      data: { dispute }
    });
  } catch (error) {
    console.error('Update dispute error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Resolve dispute
exports.resolveDispute = async (req, res) => {
  try {
    const Dispute = require('../models/Dispute');
    const { disputeId } = req.params;
    const { resolution } = req.body;

    if (!resolution || !resolution.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Resolution text is required'
      });
    }

    const dispute = await Dispute.findByIdAndUpdate(
      disputeId,
      {
        status: 'resolved',
        resolution: resolution.trim(),
        resolvedBy: req.user.userId,
        resolvedAt: new Date()
      },
      { new: true }
    ).populate('studentId', 'firstName lastName email')
     .populate('tutorId', 'firstName lastName email')
     .populate('bookingId', 'sessionDate subject.name')
     .populate('resolvedBy', 'firstName lastName');

    if (!dispute) {
      return res.status(404).json({
        success: false,
        message: 'Dispute not found'
      });
    }

    res.json({
      success: true,
      message: 'Dispute resolved successfully',
      data: { dispute }
    });
  } catch (error) {
    console.error('Resolve dispute error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Add message to dispute
exports.addDisputeMessage = async (req, res) => {
  try {
    const Dispute = require('../models/Dispute');
    const { disputeId } = req.params;
    const { message } = req.body;

    if (!message || !message.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Message text is required'
      });
    }

    const dispute = await Dispute.findById(disputeId);
    if (!dispute) {
      return res.status(404).json({
        success: false,
        message: 'Dispute not found'
      });
    }

    dispute.messages.push({
      sender: req.user.userId,
      senderRole: 'admin',
      message: message.trim(),
      timestamp: new Date()
    });

    // Update status to in_progress if it was open
    if (dispute.status === 'open') {
      dispute.status = 'in_progress';
    }

    await dispute.save();
    await dispute.populate('messages.sender', 'firstName lastName');

    res.json({
      success: true,
      message: 'Message added successfully',
      data: { dispute }
    });
  } catch (error) {
    console.error('Add dispute message error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};
