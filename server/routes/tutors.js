const express = require('express');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Get all tutors (for students to browse)
router.get('/', async (req, res) => {
  try {
    const TutorProfile = require('../models/TutorProfile');
    const { 
      page = 1, 
      limit = 20, 
      subject, 
      minPrice, 
      maxPrice, 
      rating,
      search,
      teachingMode,
      location 
    } = req.query;

    const filter = { status: 'approved', isActive: true };
    
    // Build $and array for complex queries
    const andConditions = [];
    
    // Subject filter
    if (subject && subject !== 'All Subjects') {
      andConditions.push({ 'subjects.name': { $regex: subject, $options: 'i' } });
    }
    
    // Price range filter
    if (minPrice || maxPrice) {
      const priceFilter = {};
      if (minPrice) priceFilter.$gte = parseFloat(minPrice);
      if (maxPrice) priceFilter.$lte = parseFloat(maxPrice);
      andConditions.push({ 'pricing.hourlyRate': priceFilter });
    }
    
    // Rating filter
    if (rating) {
      andConditions.push({ 'stats.averageRating': { $gte: parseFloat(rating) } });
    }

    // Teaching mode filter
    if (teachingMode && teachingMode !== 'All Modes') {
      if (teachingMode === 'Online') {
        andConditions.push({ 'teachingMode.online': true });
      } else if (teachingMode === 'In-Person') {
        andConditions.push({ 'teachingMode.inPerson': true });
      }
    }

    // Location filter
    if (location) {
      andConditions.push({ 'location.city': { $regex: location, $options: 'i' } });
    }

    // Search filter (bio and subjects only - name search will be done after populate)
    if (search) {
      andConditions.push({
        $or: [
          { bio: { $regex: search, $options: 'i' } },
          { 'subjects.name': { $regex: search, $options: 'i' } }
        ]
      });
    }

    // Combine all conditions
    if (andConditions.length > 0) {
      filter.$and = andConditions;
    }

    let tutors = await TutorProfile.find(filter)
      .populate('userId', 'firstName lastName profilePicture email')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ 'stats.averageRating': -1, 'stats.totalReviews': -1, createdAt: -1 });

    // Filter by name if search term provided (after populate)
    if (search) {
      const searchLower = search.toLowerCase();
      tutors = tutors.filter(tutor => {
        if (!tutor.userId) return false;
        const fullName = `${tutor.userId.firstName} ${tutor.userId.lastName}`.toLowerCase();
        return fullName.includes(searchLower) || 
               tutor.bio.toLowerCase().includes(searchLower) ||
               tutor.subjects.some(s => s.name.toLowerCase().includes(searchLower));
      });
    }

    const total = await TutorProfile.countDocuments(filter);

    // Format response for mobile app
    const Subject = require('../models/Subject');
    const allSubjects = await Subject.find({});
    const subjectMap = new Map(allSubjects.map(s => [s.name.toLowerCase(), s]));
    
    const formattedTutors = tutors.map(tutor => {
      if (!tutor.userId) {
        console.warn('Tutor profile missing userId:', tutor._id);
        return null;
      }
      
      // Map embedded subject names to actual Subject collection IDs
      const mappedSubjects = tutor.subjects.map(s => {
        const actualSubject = subjectMap.get(s.name.toLowerCase());
        return {
          id: actualSubject?._id?.toString() || '',
          name: s.name
        };
      }).filter(s => s.id); // Only include subjects with valid IDs
      
      return {
      id: tutor._id.toString(),
      userId: tutor.userId._id.toString(),
      name: `${tutor.userId.firstName} ${tutor.userId.lastName}`,
      firstName: tutor.userId.firstName,
      lastName: tutor.userId.lastName,
      email: tutor.userId.email,
      profilePicture: tutor.userId.profilePicture,
      bio: tutor.bio,
      subjects: mappedSubjects,
      hourlyRate: tutor.pricing?.hourlyRate || 0,
      rating: tutor.stats?.averageRating || 0,
      totalReviews: tutor.stats?.totalReviews || 0,
      totalSessions: tutor.stats?.totalSessions || 0,
      experience: tutor.experience?.years || 0,
      teachingMode: {
        online: tutor.teachingMode?.online || false,
        inPerson: tutor.teachingMode?.inPerson || false
      },
      location: tutor.location?.city || '',
      isActive: tutor.isActive,
      status: tutor.status
    };
    }).filter(t => t !== null); // Remove any null entries

    console.log(`✅ Found ${formattedTutors.length} tutors matching filters:`, { subject, search, minPrice, maxPrice });

    res.json({
      success: true,
      data: {
        tutors: formattedTutors,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('❌ Get tutors error:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Failed to get tutors',
      error: error.message
    });
  }
});

// Get current tutor's profile (must be before /:id route)
router.get('/profile', authenticate, async (req, res) => {
  try {
    console.log('✅ /profile route hit - User ID:', req.user.userId);
    const TutorProfile = require('../models/TutorProfile');
    
    // Find tutor profile by userId
    const tutor = await TutorProfile.findOne({ userId: req.user.userId })
      .populate('userId', 'firstName lastName profilePicture email')
      .populate('subjects', 'name');

    if (!tutor) {
      console.log('❌ Tutor profile not found for user:', req.user.userId);
      return res.status(404).json({
        success: false,
        message: 'Tutor profile not found'
      });
    }

    console.log('✅ Tutor profile found:', tutor._id);
    res.json({
      success: true,
      data: tutor
    });
  } catch (error) {
    console.error('Get tutor profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get tutor profile',
      error: error.message
    });
  }
});

// Get tutor by ID
router.get('/:id', async (req, res) => {
  try {
    // Prevent 'profile' from being treated as an ID
    if (req.params.id === 'profile') {
      return res.status(400).json({
        success: false,
        message: 'Invalid tutor ID. Use /api/tutors/profile endpoint instead.'
      });
    }

    const TutorProfile = require('../models/TutorProfile');
    const Review = require('../models/Review');
    
    const tutor = await TutorProfile.findById(req.params.id)
      .populate('userId', 'firstName lastName profilePicture email phone');

    if (!tutor) {
      return res.status(404).json({
        success: false,
        message: 'Tutor not found'
      });
    }

    // Calculate rating and review stats
    const reviews = await Review.find({ tutorId: tutor._id });
    const totalReviews = reviews.length;
    const averageRating = totalReviews > 0
      ? reviews.reduce((sum, review) => sum + review.rating, 0) / totalReviews
      : 0;

    // Format response with flattened structure for easy access
    const tutorData = {
      _id: tutor._id,
      userId: tutor.userId._id,
      name: `${tutor.userId.firstName} ${tutor.userId.lastName}`,
      firstName: tutor.userId.firstName,
      lastName: tutor.userId.lastName,
      email: tutor.userId.email,
      phone: tutor.userId.phone,
      profilePicture: tutor.userId.profilePicture || tutor.profilePhoto,
      bio: tutor.bio,
      headline: tutor.headline,
      experience: tutor.experience,
      education: tutor.education,
      subjects: tutor.subjects,
      pricing: tutor.pricing,
      hourlyRate: tutor.pricing?.hourlyRate,
      teachingMode: tutor.teachingMode,
      location: tutor.location,
      timezone: tutor.timezone,
      profilePhoto: tutor.profilePhoto,
      introVideo: tutor.introVideo,
      gallery: tutor.gallery,
      certifications: tutor.certifications,
      languages: tutor.languages,
      rating: averageRating,
      totalReviews: totalReviews,
      totalSessions: tutor.stats?.totalSessions || 0,
      completedSessions: tutor.stats?.completedSessions || 0,
      totalEarnings: tutor.stats?.totalEarnings || 0,
      isActive: tutor.isActive,
      isAvailable: tutor.isAvailable,
      isVerified: tutor.isVerified,
      verificationStatus: tutor.verificationStatus,
      createdAt: tutor.createdAt,
      updatedAt: tutor.updatedAt
    };

    res.json({
      success: true,
      data: tutorData
    });
  } catch (error) {
    console.error('Get tutor error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get tutor',
      error: error.message
    });
  }
});

// Toggle profile visibility (supports both PATCH and PUT)
router.patch('/profile/visibility', authenticate, async (req, res) => {
  try {
    const TutorProfile = require('../models/TutorProfile');
    const { isActive } = req.body;

    if (typeof isActive !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'isActive must be a boolean value'
      });
    }

    const profile = await TutorProfile.findOne({ userId: req.user.userId });

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: 'Tutor profile not found'
      });
    }

    profile.isActive = isActive;
    await profile.save();

    console.log(`✅ Profile visibility toggled: ${isActive ? 'Active' : 'Inactive'} for user ${req.user.userId}`);

    res.json({
      success: true,
      message: `Profile ${isActive ? 'activated' : 'deactivated'} successfully`,
      data: {
        isActive: profile.isActive
      }
    });
  } catch (error) {
    console.error('Toggle visibility error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle profile visibility',
      error: error.message
    });
  }
});

// Also support PUT method for the same endpoint
router.put('/profile/visibility', authenticate, async (req, res) => {
  try {
    const TutorProfile = require('../models/TutorProfile');
    const { isActive } = req.body;

    if (typeof isActive !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'isActive must be a boolean value'
      });
    }

    const profile = await TutorProfile.findOne({ userId: req.user.userId });

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: 'Tutor profile not found'
      });
    }

    profile.isActive = isActive;
    await profile.save();

    console.log(`✅ Profile visibility toggled: ${isActive ? 'Active' : 'Inactive'} for user ${req.user.userId}`);

    res.json({
      success: true,
      message: `Profile ${isActive ? 'activated' : 'deactivated'} successfully`,
      data: {
        isActive: profile.isActive
      }
    });
  } catch (error) {
    console.error('Toggle visibility error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle profile visibility',
      error: error.message
    });
  }
});

// Toggle accepting bookings
router.patch('/profile/availability', authenticate, async (req, res) => {
  try {
    const TutorProfile = require('../models/TutorProfile');
    const { isAvailable } = req.body;

    if (typeof isAvailable !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'isAvailable must be a boolean value'
      });
    }

    const profile = await TutorProfile.findOne({ userId: req.user.userId });

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: 'Tutor profile not found'
      });
    }

    profile.isAvailable = isAvailable;
    await profile.save();

    console.log(`✅ Booking availability toggled: ${isAvailable ? 'Accepting' : 'Not Accepting'} for user ${req.user.userId}`);

    res.json({
      success: true,
      message: `Now ${isAvailable ? 'accepting' : 'not accepting'} new bookings`,
      data: {
        isAvailable: profile.isAvailable
      }
    });
  } catch (error) {
    console.error('Toggle availability error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle booking availability',
      error: error.message
    });
  }
});

// Also support PUT method for availability
router.put('/profile/availability', authenticate, async (req, res) => {
  try {
    const TutorProfile = require('../models/TutorProfile');
    const { isAvailable } = req.body;

    if (typeof isAvailable !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'isAvailable must be a boolean value'
      });
    }

    const profile = await TutorProfile.findOne({ userId: req.user.userId });

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: 'Tutor profile not found'
      });
    }

    profile.isAvailable = isAvailable;
    await profile.save();

    console.log(`✅ Booking availability toggled: ${isAvailable ? 'Accepting' : 'Not Accepting'} for user ${req.user.userId}`);

    res.json({
      success: true,
      message: `Now ${isAvailable ? 'accepting' : 'not accepting'} new bookings`,
      data: {
        isAvailable: profile.isAvailable
      }
    });
  } catch (error) {
    console.error('Toggle availability error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle booking availability',
      error: error.message
    });
  }
});

module.exports = router;