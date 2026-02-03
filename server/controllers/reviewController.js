const Review = require('../models/Review');
const Booking = require('../models/Booking');
const TutorProfile = require('../models/TutorProfile');
const notificationService = require('../services/notificationService');

// Create a review after completing a session
exports.createReview = async (req, res) => {
    try {
        const { bookingId, rating, review, categories } = req.body;
        const studentId = req.user.userId;

        // Validate required fields
        if (!bookingId || !rating) {
            return res.status(400).json({
                success: false,
                message: 'Booking ID and rating are required'
            });
        }

        // Validate rating range
        if (rating < 1 || rating > 5 || !Number.isInteger(rating)) {
            return res.status(400).json({
                success: false,
                message: 'Rating must be a whole number between 1 and 5'
            });
        }

        // Find the booking
        const booking = await Booking.findById(bookingId)
            .populate('studentId', 'firstName lastName')
            .populate('tutorId', 'userId');

        if (!booking) {
            return res.status(404).json({
                success: false,
                message: 'Booking not found'
            });
        }

        // Verify the student owns this booking
        if (booking.studentId._id.toString() !== studentId.toString()) {
            return res.status(403).json({
                success: false,
                message: 'You can only review your own bookings'
            });
        }

        // Verify booking is completed
        if (booking.status !== 'completed') {
            return res.status(400).json({
                success: false,
                message: 'You can only review completed sessions'
            });
        }

        // Check if review already exists
        const existingReview = await Review.findOne({ bookingId });
        if (existingReview) {
            return res.status(400).json({
                success: false,
                message: 'You have already reviewed this session'
            });
        }

        // Create the review
        const newReview = await Review.create({
            bookingId,
            tutorId: booking.tutorId._id,
            studentId,
            rating,
            review: review || '',
            categories: categories || {},
            sessionDate: booking.sessionDate,
            subject: booking.subject?.name || 'Session'
        });

        // Update booking with rating
        await booking.addRating(studentId, rating, review, 'student');

        // Send notification to tutor
        const tutorUser = await TutorProfile.findById(booking.tutorId._id).populate('userId');
        if (tutorUser && tutorUser.userId) {
            await notificationService.createNotification({
                userId: tutorUser.userId._id,
                type: 'new_review',
                title: 'New Review Received ⭐',
                body: `${booking.studentId.firstName} rated your session ${rating} stars`,
                data: {
                    type: 'new_review',
                    reviewId: newReview._id.toString(),
                    bookingId: bookingId.toString(),
                    rating
                },
                priority: 'normal',
                actionUrl: '/tutor/reviews'
            });
        }

        // Populate the review before returning
        const populatedReview = await Review.findById(newReview._id)
            .populate('studentId', 'firstName lastName profilePicture');

        res.status(201).json({
            success: true,
            message: 'Review submitted successfully',
            data: populatedReview
        });

    } catch (error) {
        console.error('Create review error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create review',
            error: error.message
        });
    }
};

// Get reviews for a tutor
exports.getTutorReviews = async (req, res) => {
    try {
        const { tutorId } = req.params;
        const {
            page = 1,
            limit = 20,
            rating = null,
            sortBy = 'recent'
        } = req.query;

        const options = {
            page: parseInt(page),
            limit: parseInt(limit),
            rating: rating ? parseInt(rating) : null,
            sortBy
        };

        const result = await Review.getTutorReviews(tutorId, options);

        // Get rating statistics
        const ratingStats = await Review.getTutorAverageRating(tutorId);

        res.json({
            success: true,
            data: {
                ...result,
                statistics: ratingStats
            }
        });

    } catch (error) {
        console.error('Get tutor reviews error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get reviews',
            error: error.message
        });
    }
};

// Get reviews written by a student
exports.getStudentReviews = async (req, res) => {
    try {
        const { studentId } = req.params;
        const { page = 1, limit = 20 } = req.query;

        // Verify user can access these reviews
        if (req.user.userId.toString() !== studentId && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'You can only view your own reviews'
            });
        }

        const reviews = await Review.find({ studentId })
            .populate('tutorId')
            .populate({
                path: 'tutorId',
                populate: {
                    path: 'userId',
                    select: 'firstName lastName profilePicture'
                }
            })
            .sort({ createdAt: -1 })
            .limit(parseInt(limit))
            .skip((parseInt(page) - 1) * parseInt(limit));

        const total = await Review.countDocuments({ studentId });

        res.json({
            success: true,
            data: {
                reviews,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / parseInt(limit))
                }
            }
        });

    } catch (error) {
        console.error('Get student reviews error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get reviews',
            error: error.message
        });
    }
};

// Get a single review
exports.getReview = async (req, res) => {
    try {
        const { reviewId } = req.params;

        const review = await Review.findById(reviewId)
            .populate('studentId', 'firstName lastName profilePicture')
            .populate({
                path: 'tutorId',
                populate: {
                    path: 'userId',
                    select: 'firstName lastName profilePicture'
                }
            });

        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found'
            });
        }

        res.json({
            success: true,
            data: review
        });

    } catch (error) {
        console.error('Get review error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get review',
            error: error.message
        });
    }
};

// Mark review as helpful/not helpful
exports.markHelpful = async (req, res) => {
    try {
        const { reviewId } = req.params;
        const { helpful } = req.body; // true or false
        const userId = req.user.userId;

        const review = await Review.findById(reviewId);

        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found'
            });
        }

        await review.markHelpful(userId, helpful);

        res.json({
            success: true,
            message: 'Helpfulness recorded',
            data: {
                helpfulCount: review.helpful.length,
                notHelpfulCount: review.notHelpful.length
            }
        });

    } catch (error) {
        console.error('Mark helpful error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to record helpfulness',
            error: error.message
        });
    }
};

// Tutor responds to a review
exports.addTutorResponse = async (req, res) => {
    try {
        const { reviewId } = req.params;
        const { response } = req.body;
        const userId = req.user.userId;

        if (!response || response.trim().length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Response text is required'
            });
        }

        const review = await Review.findById(reviewId).populate('tutorId');

        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found'
            });
        }

        // Verify the user is the tutor being reviewed
        const tutorProfile = await TutorProfile.findOne({ userId: userId });
        if (!tutorProfile || tutorProfile._id.toString() !== review.tutorId._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'You can only respond to reviews of your own profile'
            });
        }

        // Check if response already exists
        if (review.tutorResponse && review.tutorResponse.text) {
            return res.status(400).json({
                success: false,
                message: 'You have already responded to this review'
            });
        }

        await review.addTutorResponse(response);

        // Notify student
        await notificationService.createNotification({
            userId: review.studentId,
            type: 'tutor_response',
            title: 'Tutor Responded to Your Review',
            body: `Your tutor responded to your review`,
            data: {
                type: 'tutor_response',
                reviewId: reviewId.toString()
            },
            priority: 'normal',
            actionUrl: '/student/reviews'
        });

        res.json({
            success: true,
            message: 'Response added successfully',
            data: review
        });

    } catch (error) {
        console.error('Add tutor response error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to add response',
            error: error.message
        });
    }
};

// Edit a review (within 24 hours)
exports.updateReview = async (req, res) => {
    try {
        const { reviewId } = req.params;
        const { rating, review: reviewText } = req.body;
        const userId = req.user.userId;

        const review = await Review.findById(reviewId);

        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found'
            });
        }

        // Verify the user wrote this review
        if (review.studentId.toString() !== userId.toString()) {
            return res.status(403).json({
                success: false,
                message: 'You can only edit your own reviews'
            });
        }

        await review.editReview(rating, reviewText);

        res.json({
            success: true,
            message: 'Review updated successfully',
            data: review
        });

    } catch (error) {
        console.error('Update review error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to update review',
            error: error.message
        });
    }
};

// Flag a review for moderation
exports.flagReview = async (req, res) => {
    try {
        const { reviewId } = req.params;
        const { reason } = req.body;
        const userId = req.user.userId;

        if (!reason) {
            return res.status(400).json({
                success: false,
                message: 'Flag reason is required'
            });
        }

        const review = await Review.findById(reviewId);

        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found'
            });
        }

        await review.flag(userId, reason);

        res.json({
            success: true,
            message: 'Review flagged for moderation'
        });

    } catch (error) {
        console.error('Flag review error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to flag review',
            error: error.message
        });
    }
};

// Delete a review (admin only or own review within time limit)
exports.deleteReview = async (req, res) => {
    try {
        const { reviewId } = req.params;
        const userId = req.user.userId;
        const userRole = req.user.role;

        const review = await Review.findById(reviewId);

        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found'
            });
        }

        // Check permissions
        const isOwner = review.studentId.toString() === userId.toString();
        const isAdmin = userRole === 'admin';

        if (!isOwner && !isAdmin) {
            return res.status(403).json({
                success: false,
                message: 'You do not have permission to delete this review'
            });
        }

        // If owner, check time limit (24 hours)
        if (isOwner && !isAdmin) {
            const hoursSinceCreation = (Date.now() - review.createdAt) / (1000 * 60 * 60);
            if (hoursSinceCreation > 24) {
                return res.status(403).json({
                    success: false,
                    message: 'Reviews can only be deleted within 24 hours of posting'
                });
            }
        }

        await review.remove();

        res.json({
            success: true,
            message: 'Review deleted successfully'
        });

    } catch (error) {
        console.error('Delete review error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete review',
            error: error.message
        });
    }
};
