const express = require('express');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Get student profile
router.get('/profile', authenticate, async (req, res) => {
  try {
    const StudentProfile = require('../models/StudentProfile');
    
    const profile = await StudentProfile.findOne({ userId: req.user.userId })
      .populate('userId', 'firstName lastName email profilePicture');

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: 'Student profile not found'
      });
    }

    res.json({
      success: true,
      data: { profile }
    });
  } catch (error) {
    console.error('Get student profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get student profile'
    });
  }
});

// Create or update student profile
router.post('/profile', authenticate, async (req, res) => {
  try {
    const StudentProfile = require('../models/StudentProfile');
    const profileData = { ...req.body, userId: req.user.userId };

    const profile = await StudentProfile.findOneAndUpdate(
      { userId: req.user.userId },
      profileData,
      { new: true, upsert: true, runValidators: true }
    ).populate('userId', 'firstName lastName email profilePicture');

    res.json({
      success: true,
      message: 'Student profile updated successfully',
      data: { profile }
    });
  } catch (error) {
    console.error('Update student profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update student profile'
    });
  }
});

module.exports = router;