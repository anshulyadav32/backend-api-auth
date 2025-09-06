// src/models/index.js
const { Sequelize, Op } = require('sequelize');
const path = require('path');

// Use PostgreSQL connection string from environment, or SQLite file for development
const dbPath = path.join(__dirname, '../../database.sqlite');
const sequelize = new Sequelize(process.env.STRING_POSTGRES_HOST || `sqlite:${dbPath}`, {
  dialect: process.env.STRING_POSTGRES_HOST ? 'postgres' : 'sqlite',
  logging: false,
  dialectOptions: process.env.STRING_POSTGRES_HOST ? {
    ssl: {
      require: true,
      rejectUnauthorized: false
    }
  } : {}
});

const User = require('./user')(sequelize);
const RefreshToken = require('./refreshToken')(sequelize);
const OAuthAccount = require('./oauthAccount')(sequelize);

User.hasMany(RefreshToken, { foreignKey: 'userId' });
RefreshToken.belongsTo(User, { foreignKey: 'userId' });

User.hasMany(OAuthAccount, { foreignKey: 'userId' });
OAuthAccount.belongsTo(User, { foreignKey: 'userId' });

module.exports = { sequelize, User, RefreshToken, OAuthAccount, Op };
