// src/models/refreshToken.js
const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const RefreshToken = sequelize.define('RefreshToken', {
    tokenId: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
    },
    tokenHash: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    revoked: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
  });
  return RefreshToken;
};
