const express = require('express');
const router = express.Router();
const { authenticate, storeUserToken } = require('../middleware/auth');

// Mock user database (in production, this would be in Auth Service)
const users = [];

// Register new user
router.post('/register', async (req, res, next) => {
  try {
    const { email, password, username } = req.body;

    // Validation
    if (!email || !password || !username) {
      return res.status(400).json({ message: 'Email, password, and username are required' });
    }

    // Check if user exists
    if (users.find(u => u.email === email)) {
      return res.status(409).json({ message: 'User already exists' });
    }

    // Create user (in production, hash password with bcrypt)
    const newUser = {
      id: `user_${Date.now()}`,
      email,
      username,
      password, // In production, this should be hashed
      role: 'user',
      createdAt: new Date().toISOString(),
    };

    users.push(newUser);

    // Generate token (in production, use JWT)
    const token = `mock_token_${newUser.id}_${Date.now()}`;
    
    // Store token mapping
    storeUserToken(token, {
      id: newUser.id,
      email: newUser.email,
      username: newUser.username,
      role: newUser.role,
    });

    res.status(201).json({
      message: 'User registered successfully',
      user: {
        id: newUser.id,
        email: newUser.email,
        username: newUser.username,
        role: newUser.role,
      },
      token,
    });
  } catch (error) {
    next(error);
  }
});

// Login
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    // Find user (in production, verify password hash)
    const user = users.find(u => u.email === email && u.password === password);

    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Generate token (in production, use JWT)
    const token = `mock_token_${user.id}_${Date.now()}`;
    
    // Store token mapping
    storeUserToken(token, {
      id: user.id,
      email: user.email,
      username: user.username,
      role: user.role,
    });

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role,
      },
      token,
    });
  } catch (error) {
    next(error);
  }
});

// Get current user
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const user = users.find(u => u.id === req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      id: user.id,
      email: user.email,
      username: user.username,
      role: user.role,
      createdAt: user.createdAt,
    });
  } catch (error) {
    next(error);
  }
});

// Refresh token
router.post('/refresh', authenticate, async (req, res, next) => {
  try {
    // In production, verify refresh token and generate new access token
    const token = `mock_token_${req.user.id}_${Date.now()}`;
    res.json({ token });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

