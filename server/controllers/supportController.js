const SupportTicket = require('../models/SupportTicket');
const User = require('../models/User');
const { sendEmail } = require('../utils/emailService');

// Create support ticket
exports.createTicket = async (req, res) => {
  try {
    const { subject, category, priority, description } = req.body;

    const ticket = new SupportTicket({
      user: req.user.userId,
      subject,
      category,
      priority: priority || 'medium',
      description
    });

    await ticket.save();

    // Populate user info
    await ticket.populate('user', 'firstName lastName email');

    // Send email notification to admin
    try {
      await sendEmail({
        to: process.env.ADMIN_EMAIL || 'admin@tutorapp.com',
        subject: `New Support Ticket: ${subject}`,
        html: `
          <h2>New Support Ticket</h2>
          <p><strong>From:</strong> ${ticket.user.firstName} ${ticket.user.lastName} (${ticket.user.email})</p>
          <p><strong>Category:</strong> ${category}</p>
          <p><strong>Priority:</strong> ${priority}</p>
          <p><strong>Subject:</strong> ${subject}</p>
          <p><strong>Description:</strong></p>
          <p>${description}</p>
          <p><a href="${process.env.ADMIN_URL || 'http://localhost:3000'}/support/${ticket._id}">View Ticket</a></p>
        `
      });
    } catch (emailError) {
      console.error('Failed to send email notification:', emailError);
    }

    res.status(201).json({
      success: true,
      message: 'Support ticket created successfully',
      data: ticket
    });

  } catch (error) {
    console.error('Create ticket error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create support ticket',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get user's tickets
exports.getUserTickets = async (req, res) => {
  try {
    const { status, category } = req.query;
    
    const query = { user: req.user.userId };
    if (status) query.status = status;
    if (category) query.category = category;

    const tickets = await SupportTicket.find(query)
      .populate('user', 'firstName lastName email profilePicture')
      .populate('assignedTo', 'firstName lastName')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: tickets
    });

  } catch (error) {
    console.error('Get user tickets error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get tickets',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get single ticket
exports.getTicket = async (req, res) => {
  try {
    const { ticketId } = req.params;

    const ticket = await SupportTicket.findById(ticketId)
      .populate('user', 'firstName lastName email profilePicture')
      .populate('assignedTo', 'firstName lastName')
      .populate('messages.sender', 'firstName lastName profilePicture role');

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found'
      });
    }

    // Check if user owns the ticket or is admin
    if (ticket.user._id.toString() !== req.user.userId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    res.json({
      success: true,
      data: ticket
    });

  } catch (error) {
    console.error('Get ticket error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get ticket',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Add message to ticket
exports.addMessage = async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { message } = req.body;

    const ticket = await SupportTicket.findById(ticketId)
      .populate('user', 'firstName lastName email');

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found'
      });
    }

    // Check if user owns the ticket or is admin
    if (ticket.user._id.toString() !== req.user.userId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Add message
    ticket.messages.push({
      sender: req.user.userId,
      senderRole: req.user.role === 'admin' ? 'admin' : 'user',
      message
    });

    // Update status if admin replies
    if (req.user.role === 'admin' && ticket.status === 'open') {
      ticket.status = 'in-progress';
    }

    await ticket.save();

    // Populate the new message
    await ticket.populate('messages.sender', 'firstName lastName profilePicture role');

    // Send email notification
    try {
      const recipient = req.user.role === 'admin' ? ticket.user.email : process.env.ADMIN_EMAIL;
      const senderName = req.user.role === 'admin' ? 'Support Team' : `${ticket.user.firstName} ${ticket.user.lastName}`;
      
      await sendEmail({
        to: recipient,
        subject: `New message on ticket: ${ticket.subject}`,
        html: `
          <h2>New Message on Support Ticket</h2>
          <p><strong>From:</strong> ${senderName}</p>
          <p><strong>Ticket:</strong> ${ticket.subject}</p>
          <p><strong>Message:</strong></p>
          <p>${message}</p>
          <p><a href="${process.env.ADMIN_URL || 'http://localhost:3000'}/support/${ticket._id}">View Ticket</a></p>
        `
      });
    } catch (emailError) {
      console.error('Failed to send email notification:', emailError);
    }

    res.json({
      success: true,
      message: 'Message added successfully',
      data: ticket
    });

  } catch (error) {
    console.error('Add message error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add message',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Update ticket status (admin only)
exports.updateTicketStatus = async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { status, assignedTo } = req.body;

    const ticket = await SupportTicket.findById(ticketId);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found'
      });
    }

    if (status) {
      ticket.status = status;
      if (status === 'resolved') {
        ticket.resolvedAt = new Date();
      } else if (status === 'closed') {
        ticket.closedAt = new Date();
      }
    }

    if (assignedTo) {
      ticket.assignedTo = assignedTo;
    }

    await ticket.save();

    res.json({
      success: true,
      message: 'Ticket updated successfully',
      data: ticket
    });

  } catch (error) {
    console.error('Update ticket status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update ticket',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Rate ticket (after resolution)
exports.rateTicket = async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { rating, feedback } = req.body;

    const ticket = await SupportTicket.findById(ticketId);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found'
      });
    }

    // Check if user owns the ticket
    if (ticket.user.toString() !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Check if ticket is resolved or closed
    if (ticket.status !== 'resolved' && ticket.status !== 'closed') {
      return res.status(400).json({
        success: false,
        message: 'Can only rate resolved or closed tickets'
      });
    }

    ticket.rating = rating;
    ticket.feedback = feedback;

    await ticket.save();

    res.json({
      success: true,
      message: 'Thank you for your feedback!',
      data: ticket
    });

  } catch (error) {
    console.error('Rate ticket error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to rate ticket',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get all tickets (admin only)
exports.getAllTickets = async (req, res) => {
  try {
    const { status, category, priority, search } = req.query;
    
    const query = {};
    if (status) query.status = status;
    if (category) query.category = category;
    if (priority) query.priority = priority;
    
    if (search) {
      query.$or = [
        { subject: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    const tickets = await SupportTicket.find(query)
      .populate('user', 'firstName lastName email profilePicture role')
      .populate('assignedTo', 'firstName lastName')
      .sort({ priority: -1, createdAt: -1 });

    // Get statistics
    const stats = {
      total: tickets.length,
      open: tickets.filter(t => t.status === 'open').length,
      inProgress: tickets.filter(t => t.status === 'in-progress').length,
      resolved: tickets.filter(t => t.status === 'resolved').length,
      closed: tickets.filter(t => t.status === 'closed').length
    };

    res.json({
      success: true,
      data: {
        tickets,
        stats
      }
    });

  } catch (error) {
    console.error('Get all tickets error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get tickets',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get FAQs
exports.getFAQs = async (req, res) => {
  try {
    const faqs = [
      {
        category: 'Getting Started',
        questions: [
          {
            question: 'How do I create an account?',
            answer: 'Click on "Register" and choose whether you want to be a student or tutor. Fill in your details and verify your email.'
          },
          {
            question: 'How do I find a tutor?',
            answer: 'Go to the "Find Tutors" section, use filters to search by subject, grade level, and price range. Click on a tutor to view their profile and book a session.'
          },
          {
            question: 'How do I become a tutor?',
            answer: 'Register as a tutor, complete your profile with your qualifications and subjects you teach. Once verified by admin, you can start accepting bookings.'
          }
        ]
      },
      {
        category: 'Bookings',
        questions: [
          {
            question: 'How do I book a session?',
            answer: 'Find a tutor, view their available time slots, select a time that works for you, and proceed to payment.'
          },
          {
            question: 'Can I reschedule a booking?',
            answer: 'Yes, go to your bookings, select the session, and click "Request Reschedule". The tutor will need to approve the new time.'
          },
          {
            question: 'What is the cancellation policy?',
            answer: 'You can cancel up to 24 hours before the session for a full refund. Cancellations within 24 hours may incur a fee.'
          }
        ]
      },
      {
        category: 'Payments',
        questions: [
          {
            question: 'What payment methods are accepted?',
            answer: 'We accept payments through Chapa, which supports mobile money, bank transfers, and cards.'
          },
          {
            question: 'When do tutors get paid?',
            answer: 'Payments are held in escrow and released to tutors 24 hours after the session is completed.'
          },
          {
            question: 'How do I request a refund?',
            answer: 'If you\'re not satisfied with a session, you can open a dispute within 48 hours. Our support team will review and process refunds if applicable.'
          }
        ]
      },
      {
        category: 'Technical',
        questions: [
          {
            question: 'What do I need for video sessions?',
            answer: 'You need a stable internet connection, a device with camera and microphone, and the latest version of our app.'
          },
          {
            question: 'The app is not working properly',
            answer: 'Try clearing the app cache, updating to the latest version, or reinstalling the app. If issues persist, contact support.'
          },
          {
            question: 'How do I enable notifications?',
            answer: 'Go to your profile, click on "Notifications", and enable the types of notifications you want to receive.'
          }
        ]
      }
    ];

    res.json({
      success: true,
      data: faqs
    });

  } catch (error) {
    console.error('Get FAQs error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get FAQs',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};
