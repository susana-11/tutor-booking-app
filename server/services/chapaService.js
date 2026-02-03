const axios = require('axios');
const crypto = require('crypto');

class ChapaService {
  constructor() {
    this.secretKey = process.env.CHAPA_SECRET_KEY || 'your_chapa_secret_key_here';
    this.webhookSecret = process.env.CHAPA_WEBHOOK_SECRET || 'your_webhook_secret_here';
    this.baseURL = process.env.CHAPA_BASE_URL || 'https://api.chapa.co/v1';
    this.callbackURL = process.env.CHAPA_CALLBACK_URL || 'http://localhost:5000/api/payments/callback';
    this.returnURL = process.env.CHAPA_RETURN_URL || 'http://localhost:5000/api/payments/success';
  }

  // Initialize payment
  async initializePayment({
    amount,
    email,
    firstName,
    lastName,
    txRef,
    bookingId,
    customization = {}
  }) {
    try {
      const payload = {
        amount: amount.toString(),
        currency: 'ETB',
        email,
        first_name: firstName,
        last_name: lastName,
        tx_ref: txRef,
        callback_url: `${this.callbackURL}?booking_id=${bookingId}`,
        return_url: `${this.returnURL}?booking_id=${bookingId}`,
        customization: {
          title: customization.title || 'Tutor Payment',
          description: customization.description || 'Payment for tutoring session',
          logo: customization.logo || ''
        }
      };

      const response = await axios.post(
        `${this.baseURL}/transaction/initialize`,
        payload,
        {
          headers: {
            'Authorization': `Bearer ${this.secretKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (response.data.status === 'success') {
        return {
          success: true,
          data: {
            checkoutUrl: response.data.data.checkout_url,
            reference: txRef,
            ...response.data.data
          }
        };
      } else {
        return {
          success: false,
          error: response.data.message || 'Failed to initialize payment'
        };
      }
    } catch (error) {
      console.error('Chapa initialization error:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Payment initialization failed'
      };
    }
  }

  // Verify payment
  async verifyPayment(txRef) {
    try {
      const response = await axios.get(
        `${this.baseURL}/transaction/verify/${txRef}`,
        {
          headers: {
            'Authorization': `Bearer ${this.secretKey}`
          }
        }
      );

      if (response.data.status === 'success') {
        const data = response.data.data;
        return {
          success: true,
          data: {
            status: data.status,
            amount: parseFloat(data.amount),
            currency: data.currency,
            reference: data.reference,
            transactionId: data.trx_ref,
            email: data.email,
            firstName: data.first_name,
            lastName: data.last_name,
            createdAt: data.created_at,
            updatedAt: data.updated_at
          }
        };
      } else {
        return {
          success: false,
          error: response.data.message || 'Payment verification failed'
        };
      }
    } catch (error) {
      console.error('Chapa verification error:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Payment verification failed'
      };
    }
  }

  // Verify webhook signature
  verifyWebhookSignature(payload, signature) {
    const hash = crypto
      .createHmac('sha256', this.webhookSecret)
      .update(JSON.stringify(payload))
      .digest('hex');
    
    return hash === signature;
  }

  // Process webhook
  async processWebhook(payload, signature) {
    try {
      // Verify signature
      if (!this.verifyWebhookSignature(payload, signature)) {
        return {
          success: false,
          error: 'Invalid webhook signature'
        };
      }

      // Process based on event type
      const { event, data } = payload;

      switch (event) {
        case 'charge.success':
          return {
            success: true,
            event: 'payment_success',
            data: {
              reference: data.reference,
              amount: parseFloat(data.amount),
              status: data.status,
              transactionId: data.trx_ref
            }
          };

        case 'charge.failed':
          return {
            success: true,
            event: 'payment_failed',
            data: {
              reference: data.reference,
              reason: data.message
            }
          };

        default:
          return {
            success: true,
            event: 'unknown',
            data: payload
          };
      }
    } catch (error) {
      console.error('Webhook processing error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Generate transaction reference
  generateTxRef(prefix = 'booking') {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 9);
    return `${prefix}_${timestamp}_${random}`;
  }

  // Calculate platform fee (10%)
  calculateFees(amount) {
    const platformFeePercentage = parseFloat(process.env.PLATFORM_FEE_PERCENTAGE || '10');
    const platformFee = (amount * platformFeePercentage) / 100;
    const tutorShare = amount - platformFee;

    return {
      totalAmount: amount,
      platformFee: Math.round(platformFee * 100) / 100,
      platformFeePercentage,
      tutorShare: Math.round(tutorShare * 100) / 100
    };
  }

  // Process withdrawal (mock - integrate with actual bank transfer API)
  async processWithdrawal({
    amount,
    accountNumber,
    accountName,
    bankName,
    reference
  }) {
    try {
      // In production, integrate with actual bank transfer API
      // For now, simulate withdrawal processing
      
      console.log('Processing withdrawal:', {
        amount,
        accountNumber,
        accountName,
        bankName,
        reference
      });

      // Simulate processing delay
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Simulate 95% success rate
      const success = Math.random() > 0.05;

      if (success) {
        return {
          success: true,
          data: {
            reference,
            status: 'completed',
            transactionId: `wth_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`,
            processedAt: new Date()
          }
        };
      } else {
        return {
          success: false,
          error: 'Bank transfer failed. Please try again.'
        };
      }
    } catch (error) {
      console.error('Withdrawal processing error:', error);
      return {
        success: false,
        error: error.message || 'Withdrawal processing failed'
      };
    }
  }
}

module.exports = new ChapaService();
