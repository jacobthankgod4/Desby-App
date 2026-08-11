/**
 * Paystack Configuration for Backend
 */

module.exports = {
  // API Keys - should be stored in environment variables
  publicKey: process.env.PAYSTACK_PUBLIC_KEY,
  secretKey: process.env.PAYSTACK_SECRET_KEY,

  // API Configuration
  apiUrl: 'https://api.paystack.co',
  apiVersion: 'v1',
  timeout: 30000, // 30 seconds

  // Supported currencies
  supportedCurrencies: ['NGN', 'GHS', 'ZAR', 'KES', 'USD'],
  defaultCurrency: 'NGN',

  // Payment configuration
  payment: {
    minAmount: 100, // Minimum payment amount in kobo (₦1)
    maxAmount: 50000000, // Maximum payment amount in kobo (₦500,000)
  },

  // Webhook configuration
  webhook: {
    // Paystack will send webhooks to this endpoint
    // Make sure this is publicly accessible
    url: process.env.PAYSTACK_WEBHOOK_URL || 'https://yourdomain.com/api/payments/webhook',
    timeout: 5000,
  },

  // Paystack event types to handle
  events: {
    CHARGE_SUCCESS: 'charge.success',
    CHARGE_FAILED: 'charge.failed',
    TRANSFER_SUCCESS: 'transfer.success',
    TRANSFER_FAILED: 'transfer.failed',
    TRANSFER_REVERSED: 'transfer.reversed',
    CUSTOMER_CREATION: 'customer.create',
    PLAN_CREATE: 'plan.create',
    SUBSCRIPTION_CREATE: 'subscription.create',
    SUBSCRIPTION_DISABLE: 'subscription.disable',
    SUBSCRIPTION_ENABLE: 'subscription.enable',
  },

  // Error messages
  errors: {
    INVALID_KEY: 'Invalid Paystack API key',
    NETWORK_ERROR: 'Network error occurred',
    TIMEOUT: 'Request timeout',
    INVALID_AMOUNT: 'Invalid payment amount',
    INVALID_CURRENCY: 'Currency not supported',
    INVALID_REFERENCE: 'Invalid payment reference',
    PAYMENT_NOT_FOUND: 'Payment not found',
    INVALID_SIGNATURE: 'Invalid webhook signature',
  },
};
