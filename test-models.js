// test-models.js
console.log('Testing models...');
try {
  const models = require('./src/models');
  console.log('Models loaded successfully:', Object.keys(models));
} catch(e) {
  console.error('Model error:', e.message);
  console.error('Stack:', e.stack);
}
