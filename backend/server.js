const express = require('express');
const cors = require('cors');
const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

let users = [];

app.post('/api/auth/register', (req, res) => {
  const { email, password, name, userType } = req.body;
  console.log('Register:', { email, name, userType });
  
  const newUser = {
    id: Date.now().toString(),
    email,
    name,
    userType,
    token: 'jwt-' + Date.now(),
    refreshToken: 'refresh-' + Date.now()
  };
  
  users.push(newUser);
  
  res.json({
    success: true,
    data: newUser,
    message: 'User registered successfully'
  });
});

app.post('/api/auth/login', (req, res) => {
  res.json({ success: true, data: users[0] || null });
});

app.get('/api/auth/me', (req, res) => {
  res.json(users[0] || null);
});

app.listen(port, () => {
  console.log(`Desby Mock API running at http://localhost:${port}`);
  console.log('POST /api/auth/register - Apprentice works!');
});

