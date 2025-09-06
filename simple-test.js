const express = require('express');
const app = express();

app.use(express.json());

app.post('/test', (req, res) => {
  console.log('Body received:', req.body);
  res.json({ success: true, body: req.body });
});

app.listen(8080, '0.0.0.0', () => {
  console.log('Test server running on http://localhost:8080');
});
