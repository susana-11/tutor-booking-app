const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
    // Reference to booking
    bookingId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Booking',
        required: true,
        unique: true // One review per booking
    },

    // Participants
    tutorId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'TutorProfile',
        required: true,
        index: true
    },
    studentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },

    // Rating and Review Content
    rating: {
        type: Number,
        required: true,
        min: [1, 'Rating must be at least 1'],
        max: [5, 'Rating cannot exceed 5'],
        validate: {
            validator: Number.isInteger,
            message: 'Rating must be a whole number'
        }
    },
    review: {
        type: String,
        maxlength: [1000, 'Review cannot exceed 1000 characters'],
        trim: true
    },

    // Session Information (for context)
    sessionDate: {
        type: Date,
        required: true
    },
    subject: {
        type: String,
        required: true
    },

    // Categories for more detailed feedback
    categories: {
        communication: {
            type: Number,
            min: 1,
            max: 5
        },
        expertise: {
            type: Number,
            min: 1,
            max: 5
        },
        punctuality: {
            type: Number,
            min: 1,
            max: 5
        },
        helpfulness: {
            type: Number,
            min: 1,
            max: 5
        }
    },

    // Moderation and Visibility
    isVisible: {
        type: Boolean,
        default: true
    },
    isFlagged: {
        type: Boolean,
        default: false
    },
    flagReason: String,
    flaggedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    flaggedAt: Date,

    // Moderation action
    moderationStatus: {
        type: String,
        enum: ['pending', 'approved', 'rejected', 'hidden'],
        default: 'approved'
    },
    moderatedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    moderatedAt: Date,
    moderationNote: String,

    // Helpfulness voting
    helpful: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],
    notHelpful: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],

    // Tutor Response
    tutorResponse: {
        text: {
            type: String,
            maxlength: [500, 'Response cannot exceed 500 characters']
        },
        respondedAt: Date
    },

    // Edit tracking
    isEdited: {
        type: Boolean,
        default: false
    },
    editedAt: Date,
    editHistory: [{
        rating: Number,
        review: String,
        editedAt: Date
    }]
}, {
    timestamps: true
});

// Indexes for efficient queries
reviewSchema.index({ tutorId: 1, createdAt: -1 });
reviewSchema.index({ studentId: 1, createdAt: -1 });
reviewSchema.index({ rating: 1 });
reviewSchema.index({ isVisible: 1, moderationStatus: 1 });
reviewSchema.index({ createdAt: -1 });
reviewSchema.index({ 'helpful': 1 });

// Virtual for helpfulness score
reviewSchema.virtual('helpfulnessScore').get(function () {
    return (this.helpful?.length || 0) - (this.notHelpful?.length || 0);
});

// Virtual to check if review can be edited (within 24 hours)
reviewSchema.virtual('canEdit').get(function () {
    const hoursSinceCreation = (Date.now() - this.createdAt) / (1000 * 60 * 60);
    return hoursSinceCreation < 24 && !this.isEdited;
});

// Method to mark as helpful
reviewSchema.methods.markHelpful = async function (userId, isHelpful) {
    // Remove from both arrays first
    this.helpful = this.helpful.filter(id => !id.equals(userId));
    this.notHelpful = this.notHelpful.filter(id => !id.equals(userId));

    // Add to appropriate array
    if (isHelpful) {
        this.helpful.push(userId);
    } else {
        this.notHelpful.push(userId);
    }

    return await this.save();
};

// Method to add tutor response
reviewSchema.methods.addTutorResponse = async function (responseText) {
    this.tutorResponse = {
        text: responseText,
        respondedAt: new Date()
    };
    return await this.save();
};

// Method to edit review (within time limit)
reviewSchema.methods.editReview = async function (newRating, newReviewText) {
    if (!this.canEdit) {
        throw new Error('Review can only be edited within 24 hours of posting');
    }

    // Store edit history
    this.editHistory.push({
        rating: this.rating,
        review: this.review,
        editedAt: new Date()
    });

    this.rating = newRating;
    this.review = newReviewText;
    this.isEdited = true;
    this.editedAt = new Date();

    return await this.save();
};

// Method to flag review
reviewSchema.methods.flag = async function (userId, reason) {
    this.isFlagged = true;
    this.flagReason = reason;
    this.flaggedBy = userId;
    this.flaggedAt = new Date();
    this.moderationStatus = 'pending';

    return await this.save();
};

// Static method to get tutor's average rating
reviewSchema.statics.getTutorAverageRating = async function (tutorId) {
    const stats = await this.aggregate([
        {
            $match: {
                tutorId: new mongoose.Types.ObjectId(tutorId),
                isVisible: true,
                moderationStatus: 'approved'
            }
        },
        {
            $group: {
                _id: null,
                averageRating: { $avg: '$rating' },
                totalReviews: { $sum: 1 },
                ratingDistribution: {
                    $push: '$rating'
                }
            }
        }
    ]);

    if (stats.length === 0) {
        return {
            averageRating: 0,
            totalReviews: 0,
            distribution: { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 }
        };
    }

    // Calculate distribution
    const distribution = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    stats[0].ratingDistribution.forEach(rating => {
        distribution[rating]++;
    });

    return {
        averageRating: Math.round(stats[0].averageRating * 10) / 10, // Round to 1 decimal
        totalReviews: stats[0].totalReviews,
        distribution
    };
};

// Static method to get reviews for a tutor with filters
reviewSchema.statics.getTutorReviews = async function (tutorId, options = {}) {
    const {
        page = 1,
        limit = 20,
        rating = null,
        sortBy = 'recent', // recent, helpful, rating_high, rating_low
        includeResponse = true
    } = options;

    const query = {
        tutorId: new mongoose.Types.ObjectId(tutorId),
        isVisible: true,
        moderationStatus: 'approved'
    };

    if (rating) {
        query.rating = rating;
    }

    let sort = {};
    switch (sortBy) {
        case 'recent':
            sort = { createdAt: -1 };
            break;
        case 'helpful':
            sort = { helpful: -1, createdAt: -1 };
            break;
        case 'rating_high':
            sort = { rating: -1, createdAt: -1 };
            break;
        case 'rating_low':
            sort = { rating: 1, createdAt: -1 };
            break;
        default:
            sort = { createdAt: -1 };
    }

    const reviews = await this.find(query)
        .populate('studentId', 'firstName lastName profilePicture')
        .sort(sort)
        .limit(limit)
        .skip((page - 1) * limit)
        .lean();

    const total = await this.countDocuments(query);

    return {
        reviews,
        pagination: {
            page,
            limit,
            total,
            pages: Math.ceil(total / limit)
        }
    };
};

// Post-save hook to update tutor's average rating
reviewSchema.post('save', async function (doc) {
    try {
        const TutorProfile = mongoose.model('TutorProfile');
        const tutor = await TutorProfile.findById(doc.tutorId);

        if (tutor) {
            await tutor.updateAverageRating();
        }
    } catch (error) {
        console.error('Error updating tutor rating after review save:', error);
    }
});

// Post-remove hook to update tutor's average rating
reviewSchema.post('remove', async function (doc) {
    try {
        const TutorProfile = mongoose.model('TutorProfile');
        const tutor = await TutorProfile.findById(doc.tutorId);

        if (tutor) {
            await tutor.updateAverageRating();
        }
    } catch (error) {
        console.error('Error updating tutor rating after review removal:', error);
    }
});

module.exports = mongoose.model('Review', reviewSchema);
