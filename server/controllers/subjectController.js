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
      filter.gradelevels = { $in: [gradeLevel] };
    }

    const subjects = await Subject.find(filter)
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

    const subject = await Subject.findById(id);

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
    const { name, description, category, gradeLevel, isActive } = req.body;

    // Validation
    if (!name) {
      return res.status(400).json({ 
        success: false,
        message: 'Subject name is required' 
      });
    }

    // Check if subject already exists
    const existingSubject = await Subject.findOne({ 
      name: { $regex: new RegExp(`^${name}$`, 'i') } 
    });

    if (existingSubject) {
      return res.status(400).json({ 
        success: false,
        message: 'Subject already exists' 
      });
    }

    const subject = new Subject({
      name: name.trim(),
      description,
      category: category || 'Other',
      gradelevels: gradeLevel || [],
      isActive: isActive !== undefined ? isActive : true,
    });

    await subject.save();

    res.status(201).json({
      success: true,
      message: 'Subject created successfully',
      data: subject,
    });
  } catch (error) {
    console.error('Error creating subject:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Admin: Update subject
exports.updateSubject = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, category, gradeLevel, isActive } = req.body;

    const subject = await Subject.findById(id);

    if (!subject) {
      return res.status(404).json({ 
        success: false,
        message: 'Subject not found' 
      });
    }

    // Check if name is being changed and if it conflicts
    if (name && name !== subject.name) {
      const existingSubject = await Subject.findOne({ 
        name: { $regex: new RegExp(`^${name}$`, 'i') },
        _id: { $ne: id }
      });

      if (existingSubject) {
        return res.status(400).json({ 
          success: false,
          message: 'Subject name already exists' 
        });
      }
      subject.name = name.trim();
    }

    if (description !== undefined) subject.description = description;
    if (category) subject.category = category;
    if (gradeLevel) subject.gradelevels = gradeLevel;
    if (isActive !== undefined) subject.isActive = isActive;

    await subject.save();

    res.json({
      success: true,
      message: 'Subject updated successfully',
      data: subject,
    });
  } catch (error) {
    console.error('Error updating subject:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Admin: Delete subject
exports.deleteSubject = async (req, res) => {
  try {
    const { id } = req.params;

    const subject = await Subject.findById(id);

    if (!subject) {
      return res.status(404).json({ 
        success: false,
        message: 'Subject not found' 
      });
    }

    // Soft delete - just mark as inactive
    subject.isActive = false;
    await subject.save();

    res.json({ 
      success: true,
      message: 'Subject deactivated successfully' 
    });
  } catch (error) {
    console.error('Error deleting subject:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
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
      { value: 'Elementary (K-5)', label: 'Elementary (K-5)' },
      { value: 'Middle School (6-8)', label: 'Middle School (6-8)' },
      { value: 'High School (9-12)', label: 'High School (9-12)' },
      { value: 'College/University', label: 'College/University' },
      { value: 'Adult/Professional', label: 'Adult/Professional' },
      { value: 'All Levels', label: 'All Levels' },
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
      { value: 'Mathematics', label: 'Mathematics' },
      { value: 'Sciences', label: 'Sciences' },
      { value: 'Languages', label: 'Languages' },
      { value: 'Social Studies', label: 'Social Studies' },
      { value: 'Arts & Humanities', label: 'Arts & Humanities' },
      { value: 'Technology & Computing', label: 'Technology & Computing' },
      { value: 'Business & Economics', label: 'Business & Economics' },
      { value: 'Test Preparation', label: 'Test Preparation' },
      { value: 'Music & Performing Arts', label: 'Music & Performing Arts' },
      { value: 'Sports & Fitness', label: 'Sports & Fitness' },
      { value: 'Life Skills', label: 'Life Skills' },
      { value: 'Other', label: 'Other' },
    ];

    res.json(categories);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
