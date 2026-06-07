const https = require('https');
const crypto = require('crypto');

// The Signing Key shared between Uber and Desby
const SIGNING_KEY = 'Desby_Logistics_Handshake_9922';

// Simulated Uber Webhook Payload
const payload = {
  event_type: 'delivery.status_changed',
  resource_id: 'del_test_12345',
  status: 'pickup',
  timestamp: Date.now()
};

const payloadString = JSON.stringify(payload);

// Generate HMAC SHA256 Signature (How Uber does it)
const signature = crypto
  .createHmac('sha256', SIGNING_KEY)
  .update(payloadString)
  .digest('hex');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/uber-logistics/webhook',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Uber-Signature': signature,
    'Content-Length': payloadString.length
  }
};

console.log('--- ATOMIC WEBHOOK VERIFICATION ---');
console.log('Simulating Uber status update with HMAC Signature...');

const req = https.request(options, (res) => {
  console.log(`Status Code: ${res.statusCode}`);
  res.on('data', (d) => {
    process.stdout.write(d);
  });
});

req.on('error', (error) => {
  if (error.code === 'ECONNREFUSED') {
    console.error('❌ FAILURE: Local backend server is not running on port 3000.');
  } else {
    console.error('❌ ERROR:', error.message);
  }
});

req.write(payloadString);
req.end();
