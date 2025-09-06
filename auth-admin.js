#!/usr/bin/env node

/**
 * CLI Admin Tool for Authentication System
 * Phase 5 - Administrative Commands
 */

const { Command } = require('commander');
const { sequelize, User, RefreshToken } = require('./src/models');
const argon2 = require('argon2');

const program = new Command();

program
  .name('auth-admin')
  .description('CLI admin tool for user management')
  .version('1.0.0');

// List Users Command
program
  .command('list-users')
  .description('List users in the system')
  .option('--limit <number>', 'Number of users to display', '10')
  .action(async (options) => {
    try {
      await sequelize.authenticate();
      console.log('📋 Listing users...\n');
      
      const limit = parseInt(options.limit) || 10;
      const users = await User.findAll({
        attributes: ['id', 'email', 'username', 'role', 'mfaEnabled'],
        order: [['createdAt', 'DESC']],
        limit: limit
      });

      if (users.length === 0) {
        console.log('No users found.');
        return;
      }

      console.log(`Found ${users.length} users:`);
      console.log('ID\t\tEmail\t\t\tUsername\tRole\tMFA');
      console.log('─'.repeat(70));
      
      users.forEach(user => {
        const id = user.id.toString().substring(0, 8) + '...';
        const email = user.email.padEnd(20);
        const username = (user.username || 'N/A').padEnd(12);
        const role = user.role.padEnd(8);
        const mfa = user.mfaEnabled ? 'Yes' : 'No';
        console.log(`${id}\t${email}\t${username}\t${role}\t${mfa}`);
      });
      
    } catch (error) {
      console.error('❌ Error listing users:', error.message);
      process.exit(1);
    } finally {
      await sequelize.close();
    }
  });

// Promote User Command
program
  .command('promote')
  .description('Promote user to admin role')
  .requiredOption('--email <email>', 'User email address')
  .action(async (options) => {
    try {
      await sequelize.authenticate();
      
      const user = await User.findOne({ where: { email: options.email } });
      if (!user) {
        console.error(`❌ User with email ${options.email} not found.`);
        process.exit(1);
      }

      if (user.role === 'admin') {
        console.log(`ℹ️  User ${options.email} is already an admin.`);
        return;
      }

      await user.update({ role: 'admin' });
      console.log(`✅ Promoted ${options.email} to admin.`);
      
    } catch (error) {
      console.error('❌ Error promoting user:', error.message);
      process.exit(1);
    } finally {
      await sequelize.close();
    }
  });

// Demote User Command
program
  .command('demote')
  .description('Demote admin to user role')
  .requiredOption('--email <email>', 'User email address')
  .action(async (options) => {
    try {
      await sequelize.authenticate();
      
      const user = await User.findOne({ where: { email: options.email } });
      if (!user) {
        console.error(`❌ User with email ${options.email} not found.`);
        process.exit(1);
      }

      if (user.role === 'user') {
        console.log(`ℹ️  User ${options.email} is already a regular user.`);
        return;
      }

      await user.update({ role: 'user' });
      console.log(`✅ Demoted ${options.email} to user.`);
      
    } catch (error) {
      console.error('❌ Error demoting user:', error.message);
      process.exit(1);
    } finally {
      await sequelize.close();
    }
  });

// Revoke Sessions Command
program
  .command('revoke-sessions')
  .description('Revoke all refresh tokens for a user')
  .requiredOption('--email <email>', 'User email address')
  .action(async (options) => {
    try {
      await sequelize.authenticate();
      
      const user = await User.findOne({ where: { email: options.email } });
      if (!user) {
        console.error(`❌ User with email ${options.email} not found.`);
        process.exit(1);
      }

      const revokedCount = await RefreshToken.update(
        { revoked: true },
        { 
          where: { 
            userId: user.id,
            revoked: false
          }
        }
      );

      console.log(`✅ Revoked ${revokedCount[0]} refresh tokens for ${options.email}.`);
      
    } catch (error) {
      console.error('❌ Error revoking sessions:', error.message);
      process.exit(1);
    } finally {
      await sequelize.close();
    }
  });

// Disable User Command
program
  .command('disable-user')
  .description('Disable user account (revoke sessions)')
  .requiredOption('--email <email>', 'User email address')
  .action(async (options) => {
    try {
      await sequelize.authenticate();
      
      const user = await User.findOne({ where: { email: options.email } });
      if (!user) {
        console.error(`❌ User with email ${options.email} not found.`);
        process.exit(1);
      }

      // Revoke all refresh tokens to effectively disable the user
      const revokedCount = await RefreshToken.update(
        { revoked: true },
        { 
          where: { 
            userId: user.id,
            revoked: false
          }
        }
      );

      console.log(`✅ Disabled ${options.email} (sessions revoked: ${revokedCount[0]}).`);
      console.log(`ℹ️  User can still register again, but all current sessions are invalid.`);
      
    } catch (error) {
      console.error('❌ Error disabling user:', error.message);
      process.exit(1);
    } finally {
      await sequelize.close();
    }
  });

// Set Password Command
program
  .command('set-password')
  .description('Reset user password and revoke all sessions')
  .requiredOption('--email <email>', 'User email address')
  .requiredOption('--password <password>', 'New password')
  .action(async (options) => {
    try {
      await sequelize.authenticate();
      
      const user = await User.findOne({ where: { email: options.email } });
      if (!user) {
        console.error(`❌ User with email ${options.email} not found.`);
        process.exit(1);
      }

      // Hash the new password
      const passwordHash = await argon2.hash(options.password);

      // Update password and revoke all sessions in a transaction
      await sequelize.transaction(async (t) => {
        await user.update({ passwordHash }, { transaction: t });
        
        await RefreshToken.update(
          { revoked: true },
          { 
            where: { 
              userId: user.id,
              revoked: false
            },
            transaction: t
          }
        );
      });

      console.log(`✅ Password updated and sessions revoked for ${options.email}.`);
      console.log(`ℹ️  User must login again with the new password.`);
      
    } catch (error) {
      console.error('❌ Error setting password:', error.message);
      process.exit(1);
    } finally {
      await sequelize.close();
    }
  });

// Parse command line arguments
program.parse(process.argv);

// Show help if no command provided
if (!process.argv.slice(2).length) {
  program.outputHelp();
}
