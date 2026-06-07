const express = require('express');
const router = express.Router();

/**
 * Uber Direct Webhook Events:
 * - delivery.status_changed
 * - delivery.rider_status_changed
 * - delivery.courier_update
 */

router.post('/webhook', (req, res) => {
  const event = req.body;

  console.log('[Uber Webhook] Received:', event.event_type);

  // Verify Uber Webhook Signature (Future implementation)
  // Uber sends an 'X-Uber-Signature' header

  const { event_type, resource_id, status } = event;

  switch (event_type) {
    case 'delivery.status_changed':
      console.log(`[Uber Webhook] Delivery ${resource_id} status changed to ${status}`);
      // Logic to update Firestore/Database
      // updateDeliveryStatusInFirestore(resource_id, status);
      break;

    case 'delivery.rider_status_changed':
      console.log(`[Uber Webhook] Rider for delivery ${resource_id} is now ${status}`);
      break;

    default:
      console.log(`[Uber Webhook] Unhandled event type: ${event_type}`);
  }

  res.status(200).send('Webhook Received');
});

module.exports = router;
