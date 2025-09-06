// src/models/oauthAccount.js
const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const OAuthAccount = sequelize.define('OAuthAccount', {
    provider: {
      type: DataTypes.ENUM('google', 'github'),
      allowNull: false,
    },
    providerUserId: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    email: {
      type: DataTypes.STRING,
      allowNull: true, // Provider might not give email
    },
    displayName: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    profilePicture: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'Users',
        key: 'id',
      },
    },
  }, {
    indexes: [
      {
        unique: true,
        fields: ['provider', 'providerUserId'],
      },
    ],
  });

  return OAuthAccount;
};
