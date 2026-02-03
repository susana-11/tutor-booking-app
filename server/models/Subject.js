const mongoose = require('mongoose');

const subjectSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Subject name is required'],
    trim: true,
    unique: true,
    maxlength: [100, 'Subject name cannot exceed 100 characters']
  },
  category: {
    type: String,
    required: [true, 'Category is required'],
    enum: [
      'Mathematics',
      'Sciences',
      'Languages',
      'Social Studies',
      'Arts & Humanities',
      'Technology & Computing',
      'Business & Economics',
      'Test Preparation',
      'Music & Performing Arts',
      'Sports & Fitness',
      'Life Skills',
      'Other'
    ]
  },
  description: {
    type: String,
    maxlength: [500, 'Description cannot exceed 500 characters']
  },
  gradelevels: [{
    type: String,
    enum: [
      'Elementary (K-5)',
      'Middle School (6-8)',
      'High School (9-12)',
      'College/University',
      'Adult/Professional',
      'All Levels'
    ]
  }],
  isActive: {
    type: Boolean,
    default: true
  },
  icon: {
    type: String,
    default: null
  },
  color: {
    type: String,
    default: '#667eea'
  },
  // Statistics
  totalTutors: {
    type: Number,
    default: 0
  },
  totalSessions: {
    type: Number,
    default: 0
  },
  averageRating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  },
  // SEO and search
  keywords: [String],
  searchTags: [String]
}, {
  timestamps: true
});

// Indexes
subjectSchema.index({ name: 1 });
subjectSchema.index({ category: 1 });
subjectSchema.index({ isActive: 1 });
subjectSchema.index({ keywords: 1 });

// Virtual for formatted name
subjectSchema.virtual('displayName').get(function() {
  return this.name.charAt(0).toUpperCase() + this.name.slice(1);
});

// Static method to get subjects by category
subjectSchema.statics.getByCategory = function(category) {
  return this.find({ category, isActive: true }).sort({ name: 1 });
};

// Static method to search subjects
subjectSchema.statics.search = function(query) {
  return this.find({
    $and: [
      { isActive: true },
      {
        $or: [
          { name: { $regex: query, $options: 'i' } },
          { keywords: { $in: [new RegExp(query, 'i')] } },
          { searchTags: { $in: [new RegExp(query, 'i')] } }
        ]
      }
    ]
  }).sort({ name: 1 });
};

// Update tutor count when tutors are added/removed
subjectSchema.methods.updateTutorCount = async function() {
  const TutorProfile = mongoose.model('TutorProfile');
  const count = await TutorProfile.countDocuments({
    'subjects.name': this.name,
    status: 'approved',
    isActive: true
  });
  this.totalTutors = count;
  return this.save();
};

module.exports = mongoose.model('Subject', subjectSchema);