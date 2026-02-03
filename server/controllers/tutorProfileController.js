const TutorProfile = require('../models/TutorProfile');
const User = require('../models/User');

// Get tutor profile
exports.getProfile = async (req, res) => {
  try {
    const { userId } = req.params;

    const profile = await TutorProfile.findOne({ userId }).populate('userId', 'firstName lastName email phone profilePicture');

    if (!profile) {
      return res.status(404).json({ message: 'Tutor profile not found' });
    }

    // Only show active profiles to others
    if (profile.userId._id.toString() !== req.user?.userId && !profile.isActive) {
      return res.status(403).json({ message: 'This tutor profile is not available' });
    }

    res.json(profile);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get current tutor's profile
exports.getMyProfile = async (req, res) => {
  try {
    const userId = req.user.userId;

    let profile = await TutorProfile.findOne({ userId }).populate('userId', 'firstName lastName email phone profilePicture');

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: 'Tutor profile not found. Please complete your profile.'
      });
    }

    // Format the response to match mobile app expectations
    const formattedProfile = {
      id: profile._id,
      userId: profile.userId._id,
      firstName: profile.userId.firstName,
      lastName: profile.userId.lastName,
      email: profile.userId.email,
      phone: profile.userId.phone,
      profilePicture: profile.userId.profilePicture,
      bio: profile.bio,
      subjects: profile.subjects.map(s => s.name),
      grades: [...new Set(profile.subjects.flatMap(s => s.gradelevels || []))], // Get unique grades from all subjects
      hourlyRate: profile.pricing?.hourlyRate || 0,
      experience: profile.experience?.description || (profile.experience?.years ? `${profile.experience.years} years` : ''),
      education: profile.education.length > 0 ? profile.education[0].degree : '',
      isAvailableOnline: profile.teachingMode?.online || false,
      isAvailableInPerson: profile.teachingMode?.inPerson || false,
      status: profile.status,
      isActive: profile.isActive,
      isAvailable: profile.isAvailable !== undefined ? profile.isAvailable : true,
      rating: profile.stats?.averageRating || 0,
      totalReviews: profile.stats?.totalReviews || 0,
      totalSessions: profile.stats?.totalSessions || 0,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt
    };

    console.log('📋 Formatted tutor profile response:', JSON.stringify(formattedProfile, null, 2));

    res.json({
      success: true,
      data: formattedProfile
    });
  } catch (error) {
    console.error('Get tutor profile error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Create tutor profile
exports.createProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const {
      bio,
      subjects,
      grades,
      hourlyRate,
      experience,
      education,
      certifications,
      languages,
      teachingStyle,
      isAvailableOnline,
      isAvailableInPerson,
      location
    } = req.body;

    console.log('Create tutor profile request:', req.body);

    // Validation
    if (!bio || !subjects || !hourlyRate) {
      console.log('Missing required fields:', { bio: !!bio, subjects: !!subjects, hourlyRate: !!hourlyRate });
      return res.status(400).json({ message: 'Bio, subjects, and hourly rate are required' });
    }

    // Check if profile already exists
    const existingProfile = await TutorProfile.findOne({ userId });
    if (existingProfile) {
      return res.status(400).json({ message: 'Tutor profile already exists' });
    }

    // Format subjects array
    const formattedSubjects = Array.isArray(subjects) ? subjects.map(subject => ({
      name: typeof subject === 'string' ? subject : subject.name || subject,
      gradelevels: grades || []
    })) : [];

    // Format education
    const formattedEducation = education ? [{
      degree: education,
      institution: 'Not specified',
      year: new Date().getFullYear()
    }] : [];

    // Format languages
    const formattedLanguages = Array.isArray(languages) ? languages.map(lang => ({
      language: typeof lang === 'string' ? lang : lang.language || lang,
      proficiency: 'Conversational'
    })) : [];

    // Format certifications
    const formattedCertifications = Array.isArray(certifications) ? certifications.map(cert => ({
      name: typeof cert === 'string' ? cert : cert.name || cert,
      issuer: 'Not specified'
    })) : [];

    const profile = new TutorProfile({
      userId,
      bio,
      subjects: formattedSubjects,
      pricing: {
        hourlyRate: parseFloat(hourlyRate),
        currency: 'USD'
      },
      experience: {
        years: experience ? parseInt(experience) || 0 : 0,
        description: `${experience} years of teaching experience`
      },
      education: formattedEducation,
      certifications: formattedCertifications,
      languages: formattedLanguages,
      teachingMode: {
        online: isAvailableOnline !== false,
        inPerson: isAvailableInPerson === true
      },
      location: typeof location === 'string' ? { city: location } : location || {},
      status: 'approved', // Auto-approve for now (in production, this would be 'pending')
      isActive: true
    });

    await profile.save();
    await profile.populate('userId', 'firstName lastName email phone profilePicture');

    // Update user profile completion status
    await User.findByIdAndUpdate(userId, { profileCompleted: true });

    // Format the response to match mobile app expectations
    const formattedProfile = {
      id: profile._id,
      userId: profile.userId._id,
      firstName: profile.userId.firstName,
      lastName: profile.userId.lastName,
      email: profile.userId.email,
      phone: profile.userId.phone,
      profilePicture: profile.userId.profilePicture,
      bio: profile.bio,
      subjects: profile.subjects.map(s => s.name),
      grades: [...new Set(profile.subjects.flatMap(s => s.gradelevels || []))], // Get unique grades from all subjects
      hourlyRate: profile.pricing?.hourlyRate || 0,
      experience: profile.experience?.description || (profile.experience?.years ? `${profile.experience.years} years` : ''),
      education: profile.education.length > 0 ? profile.education[0].degree : '',
      isAvailableOnline: profile.teachingMode?.online || false,
      isAvailableInPerson: profile.teachingMode?.inPerson || false,
      status: profile.status,
      isActive: profile.isActive,
      isAvailable: profile.isAvailable !== undefined ? profile.isAvailable : true,
      rating: profile.stats?.averageRating || 0,
      totalReviews: profile.stats?.totalReviews || 0,
      totalSessions: profile.stats?.totalSessions || 0,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt
    };

    console.log('📋 Created tutor profile response:', JSON.stringify(formattedProfile, null, 2));

    res.status(201).json({
      success: true,
      message: 'Tutor profile created successfully. Awaiting admin approval.',
      data: formattedProfile
    });
  } catch (error) {
    console.error('Create tutor profile error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Update tutor profile
exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const {
      bio,
      subjects,
      grades,
      hourlyRate,
      experience,
      education,
      certifications,
      languages,
      teachingStyle,
      isAvailableOnline,
      isAvailableInPerson,
      location,
      isActive
    } = req.body;

    let profile = await TutorProfile.findOne({ userId });

    if (!profile) {
      // If profile doesn't exist, create it using the create logic
      return exports.createProfile(req, res);
    }

    // Update existing profile
    if (bio !== undefined) profile.bio = bio;

    if (subjects !== undefined) {
      profile.subjects = Array.isArray(subjects) ? subjects.map(subject => ({
        name: typeof subject === 'string' ? subject : subject.name || subject,
        gradelevels: grades || profile.subjects[0]?.gradelevels || []
      })) : profile.subjects;
    }

    if (hourlyRate !== undefined) {
      if (!profile.pricing) profile.pricing = {};
      profile.pricing.hourlyRate = parseFloat(hourlyRate);
    }

    if (experience !== undefined) {
      if (!profile.experience) profile.experience = {};
      profile.experience.years = parseInt(experience) || 0;
      profile.experience.description = `${experience} years of teaching experience`;
    }

    if (education !== undefined) {
      profile.education = education ? [{
        degree: education,
        institution: 'Not specified',
        year: new Date().getFullYear()
      }] : profile.education;
    }

    if (certifications !== undefined) {
      profile.certifications = Array.isArray(certifications) ? certifications.map(cert => ({
        name: typeof cert === 'string' ? cert : cert.name || cert,
        issuer: 'Not specified'
      })) : profile.certifications;
    }

    if (languages !== undefined) {
      profile.languages = Array.isArray(languages) ? languages.map(lang => ({
        language: typeof lang === 'string' ? lang : lang.language || lang,
        proficiency: 'Conversational'
      })) : profile.languages;
    }

    if (isAvailableOnline !== undefined || isAvailableInPerson !== undefined) {
      if (!profile.teachingMode) profile.teachingMode = {};
      profile.teachingMode.online = isAvailableOnline !== undefined ? isAvailableOnline : profile.teachingMode.online;
      profile.teachingMode.inPerson = isAvailableInPerson !== undefined ? isAvailableInPerson : profile.teachingMode.inPerson;
    }

    if (location !== undefined) {
      profile.location = typeof location === 'string' ? { city: location } : location || profile.location;
    }

    if (isActive !== undefined) profile.isActive = isActive;

    await profile.save();
    await profile.populate('userId', 'firstName lastName email phone profilePicture');

    // Update user profile completion status
    await User.findByIdAndUpdate(userId, { profileCompleted: true });

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: { profile }
    });
  } catch (error) {
    console.error('Update tutor profile error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Upload certificate
exports.uploadCertificate = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { certificateName, fileUrl } = req.body;

    if (!certificateName || !fileUrl) {
      return res.status(400).json({ message: 'Certificate name and file URL are required' });
    }

    const profile = await TutorProfile.findOne({ userId });

    if (!profile) {
      return res.status(404).json({ message: 'Tutor profile not found' });
    }

    profile.certificates.push({
      name: certificateName,
      fileUrl,
    });

    await profile.save();

    res.json({
      message: 'Certificate uploaded successfully',
      profile,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Toggle profile visibility
exports.toggleVisibility = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { isActive } = req.body;

    const profile = await TutorProfile.findOne({ userId });

    if (!profile) {
      return res.status(404).json({ message: 'Tutor profile not found' });
    }

    profile.isActive = isActive;
    await profile.save();

    res.json({
      message: `Profile ${isActive ? 'activated' : 'deactivated'} successfully`,
      profile,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all tutors (for students to browse)
exports.getAllTutors = async (req, res) => {
  try {
    const { subject, minPrice, maxPrice, teachingMode, location, minRating, search } = req.query;

    let filter = {
      status: 'approved',
      isActive: true,
    };

    if (subject) {
      filter['subjects.name'] = { $regex: subject, $options: 'i' };
    }

    if (minPrice || maxPrice) {
      filter['pricing.hourlyRate'] = {};
      if (minPrice) filter['pricing.hourlyRate'].$gte = parseFloat(minPrice);
      if (maxPrice) filter['pricing.hourlyRate'].$lte = parseFloat(maxPrice);
    }

    if (teachingMode) {
      if (teachingMode === 'online') {
        filter['teachingMode.online'] = true;
      } else if (teachingMode === 'inPerson') {
        filter['teachingMode.inPerson'] = true;
      }
    }

    if (location) {
      filter['location.city'] = { $regex: location, $options: 'i' };
    }

    if (minRating) {
      filter.rating = { $gte: parseFloat(minRating) };
    }

    const tutors = await TutorProfile.find(filter)
      .populate('userId', 'firstName lastName email phone profilePicture')
      .sort({ rating: -1, totalReviews: -1, createdAt: -1 });

    // Format response for better frontend consumption
    let formattedTutors = tutors.map(tutor => ({
      id: tutor._id,
      userId: tutor.userId._id,
      name: `${tutor.userId.firstName} ${tutor.userId.lastName}`,
      email: tutor.userId.email,
      profilePhoto: tutor.profilePhoto || tutor.userId.profilePicture,
      bio: tutor.bio,
      subjects: tutor.subjects,
      pricePerHour: tutor.pricePerHour,
      rating: tutor.rating,
      totalReviews: tutor.totalReviews,
      totalSessions: tutor.totalSessions,
      teachingMode: tutor.teachingMode,
      location: tutor.location,
      isActive: tutor.isActive,
      status: tutor.status,
      createdAt: tutor.createdAt,
    }));

    // Apply search filter on formatted data if search term provided
    if (search) {
      const searchTerm = search.toLowerCase();
      formattedTutors = formattedTutors.filter(tutor =>
        tutor.name.toLowerCase().includes(searchTerm) ||
        tutor.bio.toLowerCase().includes(searchTerm) ||
        tutor.subjects.some(subject => subject.name.toLowerCase().includes(searchTerm))
      );
    }

    res.json(formattedTutors);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
