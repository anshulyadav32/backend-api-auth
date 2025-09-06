// server.js
const express = require('express');
const { mountAuth } = require('./src/auth');
const { sequelize } = require('./src/models');

const app = express();
mountAuth(app);

const PORT = process.env.PORT || 8080;

sequelize.sync().then(() => {
  app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
});
