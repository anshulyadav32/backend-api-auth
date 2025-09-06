// src/auth/mfa.js
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');
const { User } = require('../models');
const { z } = require('zod');

const setupMfaSchema = z.object({
  userId: z.number(),
});

const verifyMfaSchema = z.object({
  userId: z.number(),
  token: z.string().length(6),
});

const enableMfaSchema = z.object({
  userId: z.number(),
  token: z.string().length(6),
  secret: z.string(),
});

// Generate MFA secret and QR code
async function setupMfa(req, res) {
  try {
    const { userId } = setupMfaSchema.parse(req.body);
    
    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.isMfaEnabled) {
      return res.status(400).json({ error: 'MFA is already enabled' });
    }

    // Generate secret
    const secret = speakeasy.generateSecret({
      name: `LogReg:${user.email}`,
      issuer: 'LogReg Auth System',
      length: 32,
    });

    // Generate QR code
    const qrCodeUrl = await QRCode.toDataURL(secret.otpauth_url);

    res.json({
      secret: secret.base32,
      qrCode: qrCodeUrl,
      backupCodes: generateBackupCodes(),
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

// Enable MFA after verification
async function enableMfa(req, res) {
  try {
    const { userId, token, secret } = enableMfaSchema.parse(req.body);
    
    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Verify the token
    const verified = speakeasy.totp.verify({
      secret: secret,
      encoding: 'base32',
      token: token,
      window: 2, // Allow 2 time steps for clock drift
    });

    if (!verified) {
      return res.status(400).json({ error: 'Invalid MFA token' });
    }

    // Enable MFA for user
    user.isMfaEnabled = true;
    user.mfaSecret = secret;
    await user.save();

    res.json({ 
      success: true, 
      message: 'MFA enabled successfully',
      backupCodes: generateBackupCodes()
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

// Verify MFA token during login
async function verifyMfa(req, res) {
  try {
    const { userId, token } = verifyMfaSchema.parse(req.body);
    
    const user = await User.findByPk(userId);
    if (!user || !user.isMfaEnabled) {
      return res.status(400).json({ error: 'MFA not enabled for this user' });
    }

    // Verify the token
    const verified = speakeasy.totp.verify({
      secret: user.mfaSecret,
      encoding: 'base32',
      token: token,
      window: 2,
    });

    if (!verified) {
      return res.status(401).json({ error: 'Invalid MFA token' });
    }

    res.json({ success: true, verified: true });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

// Disable MFA
async function disableMfa(req, res) {
  try {
    const { userId, token } = verifyMfaSchema.parse(req.body);
    
    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (!user.isMfaEnabled) {
      return res.status(400).json({ error: 'MFA is not enabled' });
    }

    // Verify current token before disabling
    const verified = speakeasy.totp.verify({
      secret: user.mfaSecret,
      encoding: 'base32',
      token: token,
      window: 2,
    });

    if (!verified) {
      return res.status(401).json({ error: 'Invalid MFA token' });
    }

    // Disable MFA
    user.isMfaEnabled = false;
    user.mfaSecret = null;
    await user.save();

    res.json({ success: true, message: 'MFA disabled successfully' });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

// Generate backup codes (simple implementation)
function generateBackupCodes() {
  const codes = [];
  for (let i = 0; i < 8; i++) {
    codes.push(Math.random().toString(36).substring(2, 8).toUpperCase());
  }
  return codes;
}

module.exports = {
  setupMfa,
  enableMfa,
  verifyMfa,
  disableMfa,
};
