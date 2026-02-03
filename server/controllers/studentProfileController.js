const StudentProfile = require('../models/StudentProfile');
const User = require('../models/User');

// Get student profile
exports.getProfile = async (req, res) => {
  try {
    const { userId } = req.params;

    const profile = await StudentProfile.findOne({ userId }).populate('userId', 'firstName lastName email phone profilePicture');

    if (!profile) {
      return res.status(404).json({ message: 'Student profile not found' });
    }

    res.json(profile);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get current user's profile
exports.getMyProfile = async (req, res) => {
  try {
    const userId = req.user.userId;

    let profile = await StudentProfile.findOne({ userId }).populate('userId', 'firstName lastName email phone profilePicture');

    if (!profile) {
      // Create default profile if doesn't exist
      profile = new StudentProfile({ userId });
      await profile.save();
      profile = await profile.populate('userId', 'firstName lastName email phone profilePicture');
    }

    res.json(profile);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update student profile
exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { educationLevel, school, bio, subjects, profilePhoto } = req.body;

    let profile = await StudentProfile.findOne({ userId });

    if (!profile) {
      profile = new StudentProfile({ userId });
    }

    if (educationLevel) profile.educationLevel = educationLevel;
    if (school) profile.school = school;
    if (bio) profile.bio = bio;
    if (subjects) profile.subjects = subjects;
    if (profilePhoto) profile.profilePhoto = profilePhoto;

    await profile.save();
    await profile.populate('userId', 'firstName lastName email phone profilePicture');

    res.json({
      message: 'Profile updated successfully',
      profile,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
