#!/usr/bin/env node

/**
 * Database Backup Script
 * Automatically backs up MongoDB database with proper error handling and logging
 * 
 * Usage:
 * - Manual backup: node scripts/backup-database.js
 * - Scheduled backup: Add to cron job
 * 
 * Environment Variables Required:
 * - MONGODB_URI: MongoDB connection string
 * - BACKUP_PATH: Directory to store backups (optional, defaults to ./backups)
 * - BACKUP_RETENTION_DAYS: Number of days to keep backups (optional, defaults to 30)
 */

const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
require('dotenv').config();

class DatabaseBackup {
  constructor() {
    this.mongoUri = process.env.MONGODB_URI;
    this.backupPath = process.env.BACKUP_PATH || path.join(__dirname, '../backups');
    this.retentionDays = parseInt(process.env.BACKUP_RETION_DAYS) || 30;
    this.timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    this.backupFileName = `sns-rooster-backup-${this.timestamp}.gz`;
    this.backupFilePath = path.join(this.backupPath, this.backupFileName);
  }

  /**
   * Validate environment variables
   */
  validateEnvironment() {
    if (!this.mongoUri) {
      throw new Error('MONGODB_URI environment variable is required');
    }

    console.log('✅ Environment validation passed');
    console.log(`📁 Backup path: ${this.backupPath}`);
    console.log(`📅 Retention days: ${this.retentionDays}`);
  }

  /**
   * Create backup directory if it doesn't exist
   */
  createBackupDirectory() {
    if (!fs.existsSync(this.backupPath)) {
      fs.mkdirSync(this.backupPath, { recursive: true });
      console.log(`📁 Created backup directory: ${this.backupPath}`);
    }
  }

  /**
   * Extract database name from MongoDB URI
   */
  getDatabaseName() {
    try {
      const url = new URL(this.mongoUri);
      const dbName = url.pathname.substring(1); // Remove leading slash
      return dbName || 'sns-rooster';
    } catch (error) {
      console.warn('⚠️ Could not parse database name from URI, using default');
      return 'sns-rooster';
    }
  }

  /**
   * Perform database backup using mongodump
   */
  async performBackup() {
    return new Promise((resolve, reject) => {
      const dbName = this.getDatabaseName();
      
      // Build mongodump command
      const command = `mongodump --uri="${this.mongoUri}" --db=${dbName} --archive="${this.backupFilePath}" --gzip`;
      
      console.log(`🔄 Starting backup: ${dbName}`);
      console.log(`📁 Backup file: ${this.backupFileName}`);
      
      exec(command, { timeout: 300000 }, (error, stdout, stderr) => {
        if (error) {
          console.error('❌ Backup failed:', error.message);
          reject(error);
          return;
        }
        
        if (stderr) {
          console.warn('⚠️ Backup warnings:', stderr);
        }
        
        console.log('✅ Backup completed successfully');
        console.log(`📁 Backup saved to: ${this.backupFilePath}`);
        
        // Get file size
        const stats = fs.statSync(this.backupFilePath);
        const fileSizeInMB = (stats.size / (1024 * 1024)).toFixed(2);
        console.log(`📊 Backup size: ${fileSizeInMB} MB`);
        
        resolve(this.backupFilePath);
      });
    });
  }

  /**
   * Clean up old backups based on retention policy
   */
  cleanupOldBackups() {
    console.log(`🧹 Cleaning up backups older than ${this.retentionDays} days...`);
    
    try {
      const files = fs.readdirSync(this.backupPath);
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - this.retentionDays);
      
      let deletedCount = 0;
      
      files.forEach(file => {
        if (file.startsWith('sns-rooster-backup-') && file.endsWith('.gz')) {
          const filePath = path.join(this.backupPath, file);
          const stats = fs.statSync(filePath);
          
          if (stats.mtime < cutoffDate) {
            fs.unlinkSync(filePath);
            console.log(`🗑️ Deleted old backup: ${file}`);
            deletedCount++;
          }
        }
      });
      
      console.log(`✅ Cleanup completed: ${deletedCount} old backups deleted`);
    } catch (error) {
      console.error('❌ Cleanup failed:', error.message);
    }
  }

  /**
   * Test backup restoration (optional)
   */
  async testBackupRestoration() {
    if (process.env.TEST_RESTORE === 'true') {
      console.log('🧪 Testing backup restoration...');
      
      const testDbName = `test-restore-${Date.now()}`;
      const testBackupPath = path.join(this.backupPath, 'test-restore.gz');
      
      // Copy backup for testing
      fs.copyFileSync(this.backupFilePath, testBackupPath);
      
      return new Promise((resolve, reject) => {
        const command = `mongorestore --uri="${this.mongoUri}" --nsFrom="${this.getDatabaseName()}.*" --nsTo="${testDbName}.*" --archive="${testBackupPath}" --gzip`;
        
        exec(command, { timeout: 300000 }, (error, stdout, stderr) => {
          // Clean up test files
          try {
            fs.unlinkSync(testBackupPath);
          } catch (e) {
            // Ignore cleanup errors
          }
          
          if (error) {
            console.error('❌ Restore test failed:', error.message);
            reject(error);
            return;
          }
          
          console.log('✅ Restore test completed successfully');
          resolve();
        });
      });
    }
  }

  /**
   * Log backup information
   */
  logBackupInfo() {
    const logEntry = {
      timestamp: new Date().toISOString(),
      backupFile: this.backupFileName,
      backupPath: this.backupFilePath,
      database: this.getDatabaseName(),
      retentionDays: this.retentionDays,
      status: 'success'
    };
    
    const logPath = path.join(this.backupPath, 'backup-log.json');
    let logs = [];
    
    try {
      if (fs.existsSync(logPath)) {
        logs = JSON.parse(fs.readFileSync(logPath, 'utf8'));
      }
    } catch (error) {
      console.warn('⚠️ Could not read existing log file');
    }
    
    logs.push(logEntry);
    
    // Keep only last 100 entries
    if (logs.length > 100) {
      logs = logs.slice(-100);
    }
    
    fs.writeFileSync(logPath, JSON.stringify(logs, null, 2));
    console.log('📝 Backup logged to backup-log.json');
  }

  /**
   * Main backup process
   */
  async run() {
    try {
      console.log('🚀 Starting SNS Rooster Database Backup');
      console.log('=' .repeat(50));
      
      // Validate environment
      this.validateEnvironment();
      
      // Create backup directory
      this.createBackupDirectory();
      
      // Perform backup
      await this.performBackup();
      
      // Clean up old backups
      this.cleanupOldBackups();
      
      // Test restoration (optional)
      await this.testBackupRestoration();
      
      // Log backup info
      this.logBackupInfo();
      
      console.log('=' .repeat(50));
      console.log('✅ Database backup completed successfully!');
      
    } catch (error) {
      console.error('❌ Database backup failed:', error.message);
      process.exit(1);
    }
  }
}

// Run backup if this script is executed directly
if (require.main === module) {
  const backup = new DatabaseBackup();
  backup.run();
}

module.exports = DatabaseBackup; 