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
    const totalUsers = await User.countDocuments();
    const totalStudents = await User.countDocuments({ role: 'student' });
    const totalTutors = await User.countDocuments({ role: 'tutor' });
    const pendingTutors = await TutorProfile.countDocuments({ status: 'pending' });
    const approvedTutors = await TutorProfile.countDocuments({ status: 'approved' });

    res.json({
      totalUsers,
      totalStudents,
      totalTutors,
      pendingTutors,
      approvedTutors,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
