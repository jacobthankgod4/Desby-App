/**
 * Payment Database Model
 * Schema and queries for payment records
 */

// Mock database store (replace with real database in production)
let paymentDatabase = [];

const Payment = {
  /**
   * Create a new payment record
   */
  create: async (paymentData) => {
    try {
      const payment = {
        id: `pay_${Date.now()}`,
        reference: paymentData.reference,
        amount: paymentData.amount,
        currency: paymentData.currency || 'NGN',
        status: paymentData.status || 'pending',
        email: paymentData.email,
        orderId: paymentData.orderId,
        userId: paymentData.userId,
        metadata: paymentData.metadata || {},
        authorization: paymentData.authorization || null,
        failureReason: paymentData.failureReason || null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        paidAt: paymentData.paidAt || null,
      };

      paymentDatabase.push(payment);
      console.log('[Payment Model] Payment created:', payment.reference);
      return payment;
    } catch (error) {
      console.error('[Payment Model] Create error:', error);
      throw error;
    }
  },

  /**
   * Find payment by reference
   */
  findByReference: async (reference) => {
    try {
      const payment = paymentDatabase.find(p => p.reference === reference);
      if (!payment) {
        return null;
      }
      return payment;
    } catch (error) {
      console.error('[Payment Model] Find by reference error:', error);
      throw error;
    }
  },

  /**
   * Find payment by order ID
   */
  findByOrderId: async (orderId) => {
    try {
      const payments = paymentDatabase.filter(p => p.orderId === orderId);
      return payments;
    } catch (error) {
      console.error('[Payment Model] Find by order ID error:', error);
      throw error;
    }
  },

  /**
   * Find payments by user ID
   */
  findByUserId: async (userId) => {
    try {
      const payments = paymentDatabase.filter(p => p.userId === userId);
      return payments.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    } catch (error) {
      console.error('[Payment Model] Find by user ID error:', error);
      throw error;
    }
  },

  /**
   * Update payment status
   */
  updateStatus: async (reference, status, additionalData = {}) => {
    try {
      const index = paymentDatabase.findIndex(p => p.reference === reference);
      if (index === -1) {
        return null;
      }

      paymentDatabase[index] = {
        ...paymentDatabase[index],
        status,
        updatedAt: new Date().toISOString(),
        ...additionalData,
      };

      console.log('[Payment Model] Payment updated:', reference, '→', status);
      return paymentDatabase[index];
    } catch (error) {
      console.error('[Payment Model] Update status error:', error);
      throw error;
    }
  },

  /**
   * Mark payment as verified
   */
  markAsVerified: async (reference, verificationData) => {
    try {
      return await Payment.updateStatus(reference, 'verified', {
        paidAt: new Date().toISOString(),
        authorization: verificationData.authorization,
      });
    } catch (error) {
      console.error('[Payment Model] Mark as verified error:', error);
      throw error;
    }
  },

  /**
   * Get all payments
   */
  getAll: async () => {
    try {
      return paymentDatabase.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    } catch (error) {
      console.error('[Payment Model] Get all error:', error);
      throw error;
    }
  },

  /**
   * Get payment statistics
   */
  getStatistics: async () => {
    try {
      const total = paymentDatabase.length;
      const completed = paymentDatabase.filter(p => p.status === 'completed').length;
      const failed = paymentDatabase.filter(p => p.status === 'failed').length;
      const pending = paymentDatabase.filter(p => p.status === 'pending').length;

      const totalAmount = paymentDatabase
        .filter(p => p.status === 'completed')
        .reduce((sum, p) => sum + (p.amount || 0), 0);

      return {
        total,
        completed,
        failed,
        pending,
        totalAmount,
        averageAmount: completed > 0 ? totalAmount / completed : 0,
      };
    } catch (error) {
      console.error('[Payment Model] Get statistics error:', error);
      throw error;
    }
  },

  /**
   * Delete payment record (use with caution)
   */
  delete: async (reference) => {
    try {
      const index = paymentDatabase.findIndex(p => p.reference === reference);
      if (index === -1) {
        return null;
      }

      const deleted = paymentDatabase.splice(index, 1);
      console.log('[Payment Model] Payment deleted:', reference);
      return deleted[0];
    } catch (error) {
      console.error('[Payment Model] Delete error:', error);
      throw error;
    }
  },

  /**
   * Clear all payments (testing only)
   */
  clear: async () => {
    paymentDatabase = [];
    console.log('[Payment Model] All payments cleared');
  },
};

module.exports = Payment;
