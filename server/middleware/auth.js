const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Authenticate user
const authenticate = async (req, res, next) => {
  try {
    let token;

    // Get token from header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Get user from token
    const user = await User.findById(decoded.userId);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token. User not found.'
      });
    }

    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated.'
      });
    }

    // Add user to request
    req.user = {
      userId: user._id,
      email: user.email,
      role: user.role,
      firstName: user.firstName,
      lastName: user.lastName
    };

    next();
  } catch (error) {
    console.error('Authentication error:', error);
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token.'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expired.'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Authentication failed.'
    });
  }
};

// Authorize specific roles
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. Please authenticate first.'
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Access denied. Required role: ${roles.join(' or ')}`
      });
    }

    next();
  };
};

// Check if user has completed profile
const requireCompleteProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.userId);
    
    if (!user.profileCompleted) {
      return res.status(403).json({
        success: false,
        message: 'Please complete your profile first.',
        requiresProfileCompletion: true
      });
    }

    next();
  } catch (error) {
    console.error('Profile check error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify profile status.'
    });
  }
};

// Check if tutor is approved (for tutor-specific actions)
const requireApprovedTutor = async (req, res, next) => {
  try {
    if (req.user.role !== 'tutor') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Tutor role required.'
      });
    }

    const TutorProfile = require('../models/TutorProfile');
    const tutorProfile = await TutorProfile.findOne({ userId: req.user.userId });

    if (!tutorProfile) {
      return res.status(403).json({
        success: false,
        message: 'Tutor profile not found. Please create your profile first.',
        requiresProfileCreation: true
      });
    }

    if (tutorProfile.status !== 'approved') {
      return res.status(403).json({
        success: false,
        message: 'Your tutor profile is pending approval.',
        tutorStatus: tutorProfile.status,
        rejectionReason: tutorProfile.rejectionReason
      });
    }

    // Add tutor profile ID to request for easy access
    req.tutorProfile = tutorProfile;
    
    next();
  } catch (error) {
    console.error('Tutor approval check error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify tutor status.'
    });
  }
};

// Optional authentication (for public endpoints that can benefit from user context)
const optionalAuth = async (req, res, next) => {
  try {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (token) {
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.userId);
        
        if (user && user.isActive) {
          req.user = {
            userId: user._id,
            email: user.email,
            role: user.role,
            firstName: user.firstName,
            lastName: user.lastName
          };
        }
      } catch (error) {
        // Ignore token errors for optional auth
        console.log('Optional auth token error:', error.message);
      }
    }

    next();
  } catch (error) {
    console.error('Optional authentication error:', error);
    next(); // Continue even if optional auth fails
  }
};

module.exports = {
  authenticate,
  authorize,
  requireCompleteProfile,
  requireApprovedTutor,
  optionalAuth
};