const nodemailer = require('nodemailer');

// Create transporter
const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: process.env.EMAIL_PORT || 587,
    secure: false, // true for 465, false for other ports
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });
};

// Email templates
const templates = {
  emailVerification: (data) => ({
    subject: 'Verify Your Email - Tutor Booking App',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #667eea;">Welcome to Tutor Booking App!</h2>
        <p>Hi ${data.firstName},</p>
        <p>Thank you for registering with Tutor Booking App. Please verify your email address using the code below:</p>
        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; margin: 20px 0;">
          <h1 style="color: #667eea; font-size: 32px; margin: 0; letter-spacing: 5px;">${data.otp}</h1>
        </div>
        <p>This code will expire in ${data.expiresIn}.</p>
        <p>If you didn't create an account with us, please ignore this email.</p>
        <hr style="margin: 30px 0;">
        <p style="color: #666; font-size: 12px;">
          This is an automated email. Please do not reply to this message.
        </p>
      </div>
    `
  }),

  passwordReset: (data) => ({
    subject: 'Password Reset Request - Tutor Booking App',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #667eea;">Password Reset Request</h2>
        <p>Hi ${data.firstName},</p>
        <p>You requested a password reset for your Tutor Booking App account.</p>
        <p>Click the button below to reset your password:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${data.resetUrl}" 
             style="background-color: #667eea; color: white; padding: 12px 30px; 
                    text-decoration: none; border-radius: 5px; display: inline-block;">
            Reset Password
          </a>
        </div>
        <p>Or copy and paste this link in your browser:</p>
        <p style="word-break: break-all; color: #667eea;">${data.resetUrl}</p>
        <p>This link will expire in ${data.expiresIn}.</p>
        <p>If you didn't request a password reset, please ignore this email.</p>
        <hr style="margin: 30px 0;">
        <p style="color: #666; font-size: 12px;">
          This is an automated email. Please do not reply to this message.
        </p>
      </div>
    `
  }),

  bookingConfirmation: (data) => ({
    subject: 'Booking Confirmation - Tutor Booking App',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #667eea;">Booking Confirmed!</h2>
        <p>Hi ${data.studentName},</p>
        <p>Your tutoring session has been confirmed with the following details:</p>
        <div style="background-color: #f8f9fa; padding: 20px; margin: 20px 0; border-radius: 5px;">
          <p><strong>Tutor:</strong> ${data.tutorName}</p>
          <p><strong>Subject:</strong> ${data.subject}</p>
          <p><strong>Date:</strong> ${data.date}</p>
          <p><strong>Time:</strong> ${data.time}</p>
          <p><strong>Duration:</strong> ${data.duration}</p>
          <p><strong>Mode:</strong> ${data.mode}</p>
          <p><strong>Total Amount:</strong> $${data.amount}</p>
        </div>
        <p>You will receive a reminder 1 hour before your session.</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${data.sessionLink}" 
             style="background-color: #667eea; color: white; padding: 12px 30px; 
                    text-decoration: none; border-radius: 5px; display: inline-block;">
            Join Session
          </a>
        </div>
        <p>If you need to reschedule or cancel, please do so at least 24 hours in advance.</p>
        <hr style="margin: 30px 0;">
        <p style="color: #666; font-size: 12px;">
          This is an automated email. Please do not reply to this message.
        </p>
      </div>
    `
  }),

  sessionReminder: (data) => ({
    subject: 'Session Reminder - Starting Soon!',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #667eea;">Session Starting Soon!</h2>
        <p>Hi ${data.studentName},</p>
        <p>This is a reminder that your tutoring session is starting in 1 hour:</p>
        <div style="background-color: #f8f9fa; padding: 20px; margin: 20px 0; border-radius: 5px;">
          <p><strong>Tutor:</strong> ${data.tutorName}</p>
          <p><strong>Subject:</strong> ${data.subject}</p>
          <p><strong>Time:</strong> ${data.time}</p>
          <p><strong>Duration:</strong> ${data.duration}</p>
        </div>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${data.sessionLink}" 
             style="background-color: #667eea; color: white; padding: 12px 30px; 
                    text-decoration: none; border-radius: 5px; display: inline-block;">
            Join Session Now
          </a>
        </div>
        <p>Make sure you have a stable internet connection and any required materials ready.</p>
        <hr style="margin: 30px 0;">
        <p style="color: #666; font-size: 12px;">
          This is an automated email. Please do not reply to this message.
        </p>
      </div>
    `
  })
};

// Send email function
const sendEmail = async ({ to, subject, template, data, html, text }) => {
  try {
    console.log(`📧 Attempting to send email to: ${to}, template: ${template}`);
    
    // Skip email sending if no email configuration is provided
    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
      console.log('📧 Email skipped (no configuration):', { to, subject });
      return { messageId: 'skipped-no-config' };
    }

    const transporter = createTransporter();

    let emailContent = {};

    if (template && templates[template]) {
      emailContent = templates[template](data);
      subject = emailContent.subject;
      console.log(`📧 Using template: ${template} for ${to}`);
    } else if (html || text) {
      emailContent = { html, text };
      console.log(`📧 Using custom content for ${to}`);
    } else {
      throw new Error('No email content provided');
    }

    const mailOptions = {
      from: `"Tutor Booking App" <${process.env.EMAIL_USER}>`,
      to,
      subject,
      ...emailContent
    };

    console.log(`📧 Sending email with options:`, { to: mailOptions.to, subject: mailOptions.subject, from: mailOptions.from });
    
    const result = await transporter.sendMail(mailOptions);
    console.log('📧 Email sent successfully:', result.messageId, 'to:', to);
    return result;

  } catch (error) {
    console.error('📧 Email sending failed for:', to, 'Error:', error.message);
    // Don't throw error to prevent breaking the main flow
    return { messageId: 'failed', error: error.message };
  }
};

// Send bulk emails
const sendBulkEmail = async (emails) => {
  try {
    const transporter = createTransporter();
    const results = [];

    for (const email of emails) {
      try {
        const result = await sendEmail(email);
        results.push({ success: true, messageId: result.messageId, to: email.to });
      } catch (error) {
        results.push({ success: false, error: error.message, to: email.to });
      }
    }

    return results;
  } catch (error) {
    console.error('Bulk email sending failed:', error);
    throw error;
  }
};

// Verify email configuration
const verifyEmailConfig = async () => {
  try {
    const transporter = createTransporter();
    await transporter.verify();
    console.log('Email configuration verified successfully');
    return true;
  } catch (error) {
    console.error('Email configuration verification failed:', error);
    return false;
  }
};

module.exports = {
  sendEmail,
  sendBulkEmail,
  verifyEmailConfig,
  templates
};