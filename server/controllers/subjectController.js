const Subject = require('../models/Subject');

// Get all subjects (public - for tutors to select)
exports.getAllSubjects = async (req, res) => {
  try {
    const { category, gradeLevel } = req.query;

    let filter = { isActive: true };

    if (category) {
      filter.category = category;
    }

    if (gradeLevel) {
      filter.gradeLevels = { $in: [gradeLevel] };
    }

    const subjects = await Subject.find(filter)
      .populate('createdBy', 'firstName lastName')
      .sort({ category: 1, name: 1 });

    res.json(subjects);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get subject by ID
exports.getSubjectById = async (req, res) => {
  try {
    const { id } = req.params;

    const subject = await Subject.findById(id)
      .populate('createdBy', 'firstName lastName');

    if (!subject) {
      return res.status(404).json({ message: 'Subject not found' });
    }

    res.json(subject);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Admin: Create new subject
exports.createSubject = async (req, res) => {
  try {
    const { name, description, category, gradeLevels } = req.body;
    const createdBy = req.user.userId;

    // Validation
    if (!name) {
      return res.status(400).json({ message: 'Subject name is required' });
    }

    // Check if subject already exists
    const existingSubject = await Subject.findOne({ 
      name: { $regex: new RegExp(`^${name}$`, 'i') } 
    });

    if (existingSubject) {
      return res.status(400).json({ message: 'Subject already exists' });
    }

    const subject = new Subject({
      name: name.trim(),
      description,
      category: category || 'other',
      gradeLevels: gradeLevels || [],
      createdBy,
    });

    await subject.save();
    await subject.populate('createdBy', 'firstName lastName');

    res.status(201).json({
      message: 'Subject created successfully',
      subject,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Admin: Update subject
exports.updateSubject = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, category, gradeLevels, isActive } = req.body;

    const subject = await Subject.findById(id);

    if (!subject) {
      return res.status(404).json({ message: 'Subject not found' });
    }

    // Check if name is being changed and if it conflicts
    if (name && name !== subject.name) {
      const existingSubject = await Subject.findOne({ 
        name: { $regex: new RegExp(`^${name}$`, 'i') },
        _id: { $ne: id }
      });

      if (existingSubject) {
        return res.status(400).json({ message: 'Subject name already exists' });
      }
      subject.name = name.trim();
    }

    if (description !== undefined) subject.description = description;
    if (category) subject.category = category;
    if (gradeLevels) subject.gradeLevels = gradeLevels;
    if (isActive !== undefined) subject.isActive = isActive;

    await subject.save();
    await subject.populate('createdBy', 'firstName lastName');

    res.json({
      message: 'Subject updated successfully',
      subject,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Admin: Delete subject
exports.deleteSubject = async (req, res) => {
  try {
    const { id } = req.params;

    const subject = await Subject.findById(id);

    if (!subject) {
      return res.status(404).json({ message: 'Subject not found' });
    }

    // Soft delete - just mark as inactive
    subject.isActive = false;
    await subject.save();

    res.json({ message: 'Subject deactivated successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Admin: Get all subjects (including inactive)
exports.getAllSubjectsAdmin = async (req, res) => {
  try {
    const { category, isActive } = req.query;

    let filter = {};

    if (category) {
      filter.category = category;
    }

    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }

    const subjects = await Subject.find(filter)
      .populate('createdBy', 'firstName lastName')
      .sort({ category: 1, name: 1 });

    res.json({
      success: true,
      data: subjects,
      count: subjects.length
    });
  } catch (error) {
    console.error('Error fetching subjects for admin:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Get available grade levels
exports.getGradeLevels = async (req, res) => {
  try {
    const gradeLevels = [
      { value: 'elementary', label: 'Elementary (K-5)' },
      { value: 'middle_school', label: 'Middle School (6-8)' },
      { value: 'high_school', label: 'High School (9-12)' },
      { value: 'college', label: 'College' },
      { value: 'university', label: 'University' },
      { value: 'graduate', label: 'Graduate' },
      { value: 'professional', label: 'Professional' },
    ];

    res.json(gradeLevels);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get available categories
exports.getCategories = async (req, res) => {
  try {
    const categories = [
      { value: 'mathematics', label: 'Mathematics' },
      { value: 'sciences', label: 'Sciences' },
      { value: 'languages', label: 'Languages' },
      { value: 'humanities', label: 'Humanities' },
      { value: 'arts', label: 'Arts' },
      { value: 'technology', label: 'Technology' },
      { value: 'other', label: 'Other' },
    ];

    res.json(categories);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};