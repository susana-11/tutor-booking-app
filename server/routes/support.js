const express = require('express');
const { body } = require('express-validator');
const supportController = require('../controllers/supportController');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const createTicketValidation = [
  body('subject')
    .trim()
    .isLength({ min: 5, max: 200 })
    .withMessage('Subject must be between 5 and 200 characters'),
  body('category')
    .isIn(['technical', 'payment', 'booking', 'account', 'general', 'other'])
    .withMessage('Invalid category'),
  body('description')
    .trim()
    .isLength({ min: 10, max: 2000 })
    .withMessage('Description must be between 10 and 2000 characters'),
  body('priority')
    .optional()
    .isIn(['low', 'medium', 'high', 'urgent'])
    .withMessage('Invalid priority')
];

const addMessageValidation = [
  body('message')
    .trim()
    .isLength({ min: 1, max: 1000 })
    .withMessage('Message must be between 1 and 1000 characters')
];

const rateTicketValidation = [
  body('rating')
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be between 1 and 5'),
  body('feedback')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Feedback must not exceed 500 characters')
];

// Public routes
router.get('/faqs', supportController.getFAQs);

// User routes (authenticated)
router.post('/tickets', authenticate, createTicketValidation, supportController.createTicket);
router.get('/tickets', authenticate, supportController.getUserTickets);
router.get('/tickets/:ticketId', authenticate, supportController.getTicket);
router.post('/tickets/:ticketId/messages', authenticate, addMessageValidation, supportController.addMessage);
router.post('/tickets/:ticketId/rate', authenticate, rateTicketValidation, supportController.rateTicket);

// Admin routes
router.get('/admin/tickets', authenticate, authorize('admin'), supportController.getAllTickets);
router.put('/admin/tickets/:ticketId', authenticate, authorize('admin'), supportController.updateTicketStatus);

module.exports = router;
