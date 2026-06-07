const axios = require('axios');

const UBER_CLIENT_ID = 'F-2qIUzzIaIWv_PNW3PBxZFZc5fIt2jX';
const UBER_CLIENT_SECRET = 'vNCJJn1iP8DmanPhILuhoI7qB75jxQmLoygqrDIH';

async function verifyAuth() {
  console.log('--- UBER AUTH ATOMIC VERIFICATION ---');
  try {
    const response = await axios.post('https://auth.uber.com/oauth/v2/token',
      new URLSearchParams({
        'client_id': UBER_CLIENT_ID,
        'client_secret': UBER_CLIENT_SECRET,
        'grant_type': 'client_credentials',
        'scope': 'eats.deliveries'
      }), {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
      }
    );

    if (response.data.access_token) {
      console.log('✅ SUCCESS: OAuth Handshake Verified.');
      console.log('Access Token Length:', response.data.access_token.length);
      console.log('Expires In:', response.data.expires_in, 'seconds');
      console.log('Scopes:', response.data.scope);
    } else {
      console.error('❌ FAILURE: Token response missing access_token.');
    }
  } catch (error) {
    console.error('❌ FAILURE: OAuth Handshake Failed.');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else {
      console.error('Error Message:', error.message);
    }
  }
}

verifyAuth();
