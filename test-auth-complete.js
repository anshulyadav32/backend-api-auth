// test-auth-complete.js
console.log('Testing complete auth module...');
try {
  console.log('1. Loading models...');
  const models = require('./src/models');
  console.log('Models:', Object.keys(models));
  
  console.log('2. Loading controllers...');
  const controllers = require('./src/auth/controllers');
  console.log('Controllers loaded');
  
  console.log('3. Loading routes...');
  const routes = require('./src/auth/routes');
  console.log('Routes loaded');
  
  console.log('4. Loading auth index...');
  const auth = require('./src/auth');
  console.log('Auth index loaded');
  
  console.log('✅ All auth components loaded successfully!');
} catch(e) {
  console.error('❌ Error:', e.message);
  console.error('Stack:', e.stack);
}
