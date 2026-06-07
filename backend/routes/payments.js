const express = require('express');
const router = express.Router();
const crypto = require('crypto');

// Paystack Configuration
const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY || 'sk_test_fa4f1f04a3b7fab51e63cf62ffac194e82d45a80';
const PAYSTACK_PUBLIC_KEY = process.env.PAYSTACK_PUBLIC_KEY || 'pk_test_f20647b06319d6894f9476d22b4d8d8535ebbfa3';
const PAYSTACK_API_URL = 'https://api.paystack.co';

// Mock payment store (in production, use a real database)
let payments = [];

/**
 * POST /api/payments/webhook
 * Paystack webhook endpoint for payment notifications
 */
router.post('/webhook', (req, res) => {
  try {
    // Verify webhook signature
    if (!verifyPaystackSignature(req)) {
      console.error('[Paystack] Webhook signature verification failed');
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Invalid signature'
      });
    }

    const event = req.body;
    console.log('[Paystack] Webhook received:', event.event);

    // Handle different webhook events
    switch (event.event) {
      case 'charge.success':
        handleChargeSuccess(event.data);
        break;
      case 'charge.failed':
        handleChargeFailed(event.data);
        break;
      case 'transfer.success':
        handleTransferSuccess(event.data);
        break;
      case 'transfer.failed':
        handleTransferFailed(event.data);
        break;
      default:
        console.log('[Paystack] Unhandled event:', event.event);
    }

    res.status(200).json({
      success: true,
      message: 'Webhook processed'
    });
  } catch (error) {
    console.error('[Paystack] Webhook error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

/**
 * POST /api/payments/verify
 * Verify a payment with Paystack
 */
router.post('/verify', async (req, res) => {
  try {
    const { reference } = req.body;

    if (!reference) {
      return res.status(400).json({
        success: false,
        message: 'Payment reference is required'
      });
    }

    // Check local store first
    const localPayment = payments.find(p => p.reference === reference);
    if (localPayment) {
      return res.status(200).json({
        success: true,
        data: localPayment,
        message: 'Payment verified'
      });
    }

    // In production, verify with Paystack API
    // For now, create a mock verified payment
    const payment = {
      id: `pay_${Date.now()}`,
      reference: reference,
      amount: 0,
      currency: 'NGN',
      status: 'success',
      paidAt: new Date().toISOString(),
      orderId: `ORD_${reference}`,
      email: 'user@example.com',
      authorization: {
        authorization_url: 'https://paystack.com',
        access_code: reference,
        reference: reference
      }
    };

    payments.push(payment);

    res.status(200).json({
      success: true,
      data: payment,
      message: 'Payment verified successfully'
    });
  } catch (error) {
    console.error('[Paystack] Verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Payment verification failed',
      error: error.message
    });
  }
});

/**
 * GET /api/payments/:reference
 * Get payment details
 */
router.get('/:reference', (req, res) => {
  try {
    const { reference } = req.params;

    const payment = payments.find(p => p.reference === reference);
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found'
      });
    }

    res.status(200).json({
      success: true,
      data: payment
    });
  } catch (error) {
    console.error('[Paystack] Get payment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get payment',
      error: error.message
    });
  }
});

/**
 * GET /api/payments/user/:userId
 * Get user's payment history
 */
router.get('/user/:userId', (req, res) => {
  try {
    const { userId } = req.params;

    const userPayments = payments.filter(p => p.userId === userId);

    res.status(200).json({
      success: true,
      data: userPayments,
      count: userPayments.length
    });
  } catch (error) {
    console.error('[Paystack] Get user payments error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get user payments',
      error: error.message
    });
  }
});

// ============ Helper Functions ============

/**
 * Verify Paystack webhook signature
 */
function verifyPaystackSignature(req) {
  try {
    const signature = req.headers['x-paystack-signature'];
    const body = JSON.stringify(req.body);
    const hash = crypto
      .createHmac('sha512', PAYSTACK_SECRET_KEY)
      .update(body)
      .digest('hex');

    return hash === signature;
  } catch (error) {
    console.error('[Paystack] Signature verification error:', error);
    return false;
  }
}

/**
 * Handle successful charge
 */
function handleChargeSuccess(data) {
  console.log('[Paystack] Processing charge.success:', {
    reference: data.reference,
    amount: data.amount,
    email: data.customer.email
  });

  const payment = {
    id: `pay_${Date.now()}`,
    reference: data.reference,
    amount: data.amount / 100, // Convert from kobo to naira
    currency: data.currency,
    status: 'completed',
    paidAt: new Date(data.paid_at).toISOString(),
    email: data.customer.email,
    orderId: data.metadata?.orderId,
    authorization: data.authorization,
    metadata: data.metadata
  };

  payments.push(payment);
  console.log('[Paystack] Payment recorded:', payment.reference);

  // TODO: Update order status in database
  // TODO: Send confirmation email
  // TODO: Trigger fulfillment workflow
}

/**
 * Handle failed charge
 */
function handleChargeFailed(data) {
  console.log('[Paystack] Processing charge.failed:', {
    reference: data.reference,
    reason: data.failure_reason
  });

  const payment = {
    id: `pay_${Date.now()}`,
    reference: data.reference,
    amount: data.amount / 100,
    currency: data.currency,
    status: 'failed',
    failureReason: data.failure_reason,
    email: data.customer.email,
    orderId: data.metadata?.orderId,
    metadata: data.metadata
  };

  payments.push(payment);
  console.log('[Paystack] Failed payment recorded:', payment.reference);

  // TODO: Notify user of failure
  // TODO: Update order status to failed
}

/**
 * Handle successful transfer
 */
function handleTransferSuccess(data) {
  console.log('[Paystack] Transfer successful:', {
    reference: data.reference,
    amount: data.amount
  });

  // TODO: Record transfer in database
  // TODO: Update user wallet balance
}

/**
 * Handle failed transfer
 */
function handleTransferFailed(data) {
  console.log('[Paystack] Transfer failed:', {
    reference: data.reference,
    reason: data.reason
  });

  // TODO: Log transfer failure
  // TODO: Notify admin
}

/**
 * Health check endpoint
 */
router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Paystack service is running',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
