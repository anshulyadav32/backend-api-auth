// src/models/index.js
const { Sequelize } = require('sequelize');
const sequelize = new Sequelize({
  dialect: 'sqlite',
  storage: './db.sqlite',
  logging: false,
});

const User = require('./user')(sequelize);
const RefreshToken = require('./refreshToken')(sequelize);

User.hasMany(RefreshToken, { foreignKey: 'userId' });
RefreshToken.belongsTo(User, { foreignKey: 'userId' });

module.exports = { sequelize, User, RefreshToken };
