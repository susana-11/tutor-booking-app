const Booking = require('../models/Booking');
const AvailabilitySlot = require('../models/AvailabilitySlot');
const TutorProfile = require('../models/TutorProfile');
const mongoose = require('mongoose');

// Create a new booking request
exports.createBookingRequest = async (req, res) => {
  try {
    const {
      tutorId,
      slotId,
      studentId,
      studentName,
      studentEmail,
      subject,
      sessionDate,
      timeSlot,
      amount,
      notes,
      paymentMethod
    } = req.body;

    // Validate required fields
    if (!tutorId || !slotId || !studentId || !sessionDate || !timeSlot || !amount) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields'
      });
    }

    // Check if the slot is still available
    const availabilitySlot = await AvailabilitySlot.findById(slotId);
    if (!availabilitySlot) {
      return res.status(404).json({
        success: false,
        message: 'Availability slot not found'
      });
    }

    if (!availabilitySlot.canBeBooked()) {
      return res.status(400).json({
        success: false,
        message: 'This slot is no longer available for booking'
      });
    }

    // Create the booking
    const booking = new Booking({
      tutorId,
      studentId,
      slotId,
      sessionDate: new Date(sessionDate),
      startTime: timeSlot.startTime,
      endTime: timeSlot.endTime,
      duration: timeSlot.durationMinutes,
      subject,
      pricePerHour: amount / (timeSlot.durationMinutes / 60),
      totalAmount: amount,
      sessionType: 'online',
      status: 'pending',
      paymentStatus: 'pending',
      payment: {
        amount: amount,
        status: 'pending',
        method: paymentMethod || 'chapa'
      },
      notes: {
        student: notes || ''
      },
      studentInfo: {
        name: studentName,
        email: studentEmail
      }
    });

    await booking.save();

    // Update the availability slot
    availabilitySlot.status = 'booked';
    availabilitySlot.booking = {
      bookingId: booking._id,
      studentId,
      studentName,
      studentEmail,
      subject,
      status: 'pending',
      amount,
      notes,
      bookedAt: new Date()
    };
    await availabilitySlot.save();

    // Populate booking details
    await booking.populate([
      { path: 'studentId', select: 'firstName lastName email profilePicture' },
      { path: 'tutorId', select: 'firstName lastName email profilePicture' }
    ]);

    res.status(201).json({
      success: true,
      message: 'Booking request created successfully',
      data: { booking }
    });
  } catch (error) {
    console.error('Create booking request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create booking request',
      error: error.message
    });
  }
};
