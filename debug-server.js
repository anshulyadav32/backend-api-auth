// debug-server.js
console.log('Starting debug server...');

const express = require('express');
const app = express();

app.use(express.json());

app.get('/health', (req, res) => {
  console.log('Health check received');
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.post('/test', (req, res) => {
  console.log('Test endpoint hit with body:', req.body);
  res.json({ received: req.body, success: true });
});

const PORT = 8080;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Debug server running on http://localhost:${PORT}`);
});
