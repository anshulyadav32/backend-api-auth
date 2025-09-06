// test-controllers.js
console.log('Testing controllers...');
try {
  require('./src/auth/controllers');
  console.log('Controllers OK');
} catch(e) {
  console.error('Controllers error:', e.message);
}
