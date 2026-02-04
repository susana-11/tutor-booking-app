const Booking = require('../models/Booking');
const notificationService = require('../services/notificationService');

// Check in to offline session
exports.checkIn = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { location } = req.body; // { latitude, longitude }
        const userId = req.user.userId;
        const userRole = req.user.role;

        const booking = await Booking.findById(bookingId)
            .populate('studentId', 'firstName lastName phone')
            .populate('tutorId', 'firstName lastName phone');

        if (!booking) {
            return res.status(404).json({
                success: false,
                message: 'Booking not found'
            });
        }

        // Verify user is part of this booking
        if (booking.studentId._id.toString() !== userId.toString() && 
            booking.tutorId._id.toString() !== userId.toString()) {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to check in to this session'
            });
        }

        // Check in
        await booking.checkIn(userId, userRole, location);

        // Send notification to other party
        const otherPartyId = userRole === 'student' ? booking.tutorId._id : booking.studentId._id;
        const userName = userRole === 'student' 
            ? `${booking.studentId.firstName} ${booking.studentId.lastName}`
            : `${booking.tutorId.firstName} ${booking.tutorId.lastName}`;

        await notificationService.createNotification({
            userId: otherPartyId,
            type: 'check_in',
            title: `${userName} has arrived! 📍`,
            body: `${userName} has checked in to your session`,
            data: {
                type: 'check_in',
                bookingId: bookingId.toString(),
                userRole
            },
            priority: 'high'
        });

        // If both checked in, notify both parties
        if (booking.checkIn.bothCheckedIn) {
            await notificationService.createNotification({
                userId: booking.studentId._id,
                type: 'session_ready',
                title: 'Session Ready to Start! 🎓',
                body: 'Both parties have arrived. You can start your session now.',
                data: {
                    type: 'session_ready',
                    bookingId: bookingId.toString()
                },
                priority: 'high'
            });

            await notificationService.createNotification({
                userId: booking.tutorId._id,
                type: 'session_ready',
                title: 'Session Ready to Start! 🎓',
                body: 'Both parties have arrived. You can start your session now.',
                data: {
                    type: 'session_ready',
                    bookingId: bookingId.toString()
                },
                priority: 'high'
            });
        }

        res.json({
            success: true,
            message: 'Checked in successfully',
            data: {
                checkIn: booking.checkIn,
                offlineSession: booking.offlineSession
            }
        });

    } catch (error) {
        console.error('Check-in error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to check in',
            error: error.message
        });
    }
};

// Check out from offline session
exports.checkOut = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const userId = req.user.userId;
        const userRole = req.user.role;

        const booking = await Booking.findById(bookingId)
            .populate('studentId', 'firstName lastName')
            .populate('tutorId', 'firstName lastName');

        if (!booking) {
            return res.status(404).json({
                success: false,
                message: 'Booking not found'
            });
        }

        // Verify user is part of this booking
        if (booking.studentId._id.toString() !== userId.toString() && 
            booking.tutorId._id.toString() !== userId.toString()) {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to check out from this session'
            });
        }

        // Check out
        await booking.checkOut(userId, userRole);

        // Send notification to other party
        const otherPartyId = userRole === 'student' ? booking.tutorId._id : booking.studentId._id;
        const userName = userRole === 'student' 
            ? `${booking.studentId.firstName} ${booking.studentId.lastName}`
            : `${booking.tutorId.firstName} ${booking.tutorId.lastName}`;

        await notificationService.createNotification({
            userId: otherPartyId,
            type: 'check_out',
            title: `${userName} has checked out`,
            body: `${userName} has ended the session`,
            data: {
                type: 'check_out',
                bookingId: bookingId.toString(),
                userRole
            },
            priority: 'normal'
        });

        // If both checked out, send completion notifications
        if (booking.checkOut.bothCheckedOut) {
            await notificationService.createNotification({
                userId: booking.studentId._id,
                type: 'session_completed',
                title: 'Session Completed! ✅',
                body: 'Your session has ended. Please rate your experience.',
                data: {
                    type: 'session_completed',
                    bookingId: bookingId.toString()
                },
                priority: 'normal',
                actionUrl: `/create-review/${bookingId}`
            });

            await notificationService.createNotification({
                userId: booking.tutorId._id,
                type: 'session_completed',
                title: 'Session Completed! ✅',
                body: 'Your session has ended. Payment will be released in 24 hours.',
                data: {
                    type: 'session_completed',
                    bookingId: bookingId.toString()
                },
                priority: 'normal'
            });
        }

        res.json({
            success: true,
            message: 'Checked out successfully',
            data: {
                checkOut: booking.checkOut,
                offlineSession: booking.offlineSession,
                status: booking.status
            }
        });

    } catch (error) {
        console.error('Check-out error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to check out',
            error: error.message
        });
    }
};

// Get check-in status
exports.getCheckInStatus = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId)
            .select('checkIn checkOut offlineSession sessionType location')
            .populate('studentId', 'firstName lastName')
            .populate('tutorId', 'firstName lastName');

        if (!booking) {
            return res.status(404).json({
                success: false,
                message: 'Booking not found'
            });
        }

        res.json({
            success: true,
            data: {
                checkIn: booking.checkIn,
                checkOut: booking.checkOut,
                offlineSession: booking.offlineSession,
                location: booking.location,
                sessionType: booking.sessionType
            }
        });

    } catch (error) {
        console.error('Get check-in status error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get check-in status',
            error: error.message
        });
    }
};

// Notify running late
exports.notifyRunningLate = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { estimatedArrival, reason } = req.body;
        const userId = req.user.userId;
        const userRole = req.user.role;

        const booking = await Booking.findById(bookingId)
            .populate('studentId', 'firstName lastName')
            .populate('tutorId', 'firstName lastName');

        if (!booking) {
            return res.status(404).json({
                success: false,
                message: 'Booking not found'
            });
        }

        // Verify user is part of this booking
        if (booking.studentId._id.toString() !== userId.toString() && 
            booking.tutorId._id.toString() !== userId.toString()) {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to update this session'
            });
        }

        // Notify running late
        await booking.notifyRunningLate(userId, userRole, new Date(estimatedArrival), reason);

        // Send notification to other party
        const otherPartyId = userRole === 'student' ? booking.tutorId._id : booking.studentId._id;
        const userName = userRole === 'student' 
            ? `${booking.studentId.firstName} ${booking.studentId.lastName}`
            : `${booking.tutorId.firstName} ${booking.tutorId.lastName}`;

        const arrivalTime = new Date(estimatedArrival).toLocaleTimeString('en-US', {
            hour: 'numeric',
            minute: '2-digit'
        });

        await notificationService.createNotification({
            userId: otherPartyId,
            type: 'running_late',
            title: `${userName} is running late ⏰`,
            body: `Expected arrival: ${arrivalTime}. ${reason || ''}`,
            data: {
                type: 'running_late',
                bookingId: bookingId.toString(),
                estimatedArrival,
                reason
            },
            priority: 'high'
        });

        res.json({
            success: true,
            message: 'Running late notification sent',
            data: {
                offlineSession: booking.offlineSession
            }
        });

    } catch (error) {
        console.error('Running late notification error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to send notification',
            error: error.message
        });
    }
};

// Set meeting location
exports.setMeetingLocation = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { location } = req.body;
        const userId = req.user.userId;

        const booking = await Booking.findById(bookingId);

        if (!booking) {
            return res.status(404).json({
                success: false,
                message: 'Booking not found'
            });
        }

        // Verify user is part of this booking
        if (booking.studentId.toString() !== userId.toString() && 
            booking.tutorId.toString() !== userId.toString()) {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to update this booking'
            });
        }

        // Update location
        booking.location = location;
        await booking.save();

        res.json({
            success: true,
            message: 'Meeting location updated',
            data: {
                location: booking.location
            }
        });

    } catch (error) {
        console.error('Set meeting location error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to set meeting location',
            error: error.message
        });
    }
};

// Report safety issue
exports.reportSafetyIssue = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { issueType, description } = req.body;
        const userId = req.user.userId;

        const booking = await Booking.findById(bookingId);

        if (!booking) {
            return res.status(404).json({
                success: false,
                message: 'Booking not found'
            });
        }

        // Report issue
        await booking.reportSafetyIssue(userId, issueType, description);

        // Notify admin/support team
        // In production, this would send to support system
        console.log('🚨 Safety issue reported:', {
            bookingId,
            userId,
            issueType,
            description
        });

        res.json({
            success: true,
            message: 'Safety issue reported. Our team will review it shortly.',
            data: {
                safety: booking.safety
            }
        });

    } catch (error) {
        console.error('Report safety issue error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to report safety issue',
            error: error.message
        });
    }
};

// Share session details
exports.shareSession = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { contacts } = req.body; // Array of { name, phone, email }
        const userId = req.user.userId;

        const booking = await Booking.findById(bookingId)
            .populate('studentId', 'firstName lastName')
            .populate('tutorId', 'firstName lastName');

        if (!booking) {
            return res.status(404).json({
                success: false,
                message: 'Booking not found'
            });
        }

        // Verify user is part of this booking
        if (booking.studentId._id.toString() !== userId.toString() && 
            booking.tutorId._id.toString() !== userId.toString()) {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to share this session'
            });
        }

        // Share session
        await booking.shareSession(contacts);

        // In production, send SMS/email to contacts with session details
        console.log('📤 Session shared with:', contacts);

        res.json({
            success: true,
            message: 'Session details shared successfully',
            data: {
                safety: booking.safety
            }
        });

    } catch (error) {
        console.error('Share session error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to share session',
            error: error.message
        });
    }
};

// Set emergency contact
exports.setEmergencyContact = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { name, phone, relationship } = req.body;
        const userId = req.user.userId;

        const booking = await Booking.findById(bookingId);

        if (!booking) {
            return res.status(404).json({
                success: false,
                message: 'Booking not found'
            });
        }

        // Verify user is part of this booking
        if (booking.studentId.toString() !== userId.toString() && 
            booking.tutorId.toString() !== userId.toString()) {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to update this booking'
            });
        }

        // Set emergency contact
        booking.safety.emergencyContact = { name, phone, relationship };
        await booking.save();

        res.json({
            success: true,
            message: 'Emergency contact set successfully',
            data: {
                emergencyContact: booking.safety.emergencyContact
            }
        });

    } catch (error) {
        console.error('Set emergency contact error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to set emergency contact',
            error: error.message
        });
    }
};

module.exports = exports;
