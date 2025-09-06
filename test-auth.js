// test-auth.js
console.log('Testing auth module...');
try {
  const auth = require('./src/auth');
  console.log('Auth module loaded successfully:', Object.keys(auth));
} catch(e) {
  console.error('Auth error:', e.message);
  console.error('Stack:', e.stack);
}
