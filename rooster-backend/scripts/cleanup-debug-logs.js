#!/usr/bin/env node

/**
 * Script to clean up debug logs for production deployment
 * This script removes or comments out debug console.log statements
 */

const fs = require('fs');
const path = require('path');

// Files to process (relative to rooster-backend)
const filesToProcess = [
  'controllers/attendance-controller.js',
  'controllers/admin-attendance-controller.js',
  'controllers/analytics-controller.js',
  'controllers/employee-controller.js',
  'controllers/payroll-controller.js',
  'middleware/auth.js',
  'routes/adminAttendanceRoutes.js',
  'routes/employeeRoutes.js',
  'routes/payrollRoutes.js',
  'services/fcm-service.js',
  'services/emailService.js',
  'scheduler.js',
  'middleware/upload.js',
  'gcsUpload.js'
];

// Debug log patterns to remove or comment out
const debugPatterns = [
  /console\.log\(/g,
  /console\.debug\(/g,
  /console\.warn\(/g,
  /console\.error\(/g,
  /DEBUG:/g,
  /JWT_SECRET used for verification:/g,
  /EMP RECORD for user/g,
  /=== ADMIN OVERVIEW DEBUG ===/g,
  /=== LOGO LOADING DEBUG ===/g,
  /=== PAYSLIP COMPANY INFO DEBUG ===/g,
  /SCHEDULER:/g,
  /EMPLOYEE ROUTER:/g,
  /EMPLOYEE ROUTES:/g,
  /ADMIN ATTENDANCE FILTER:/g,
  /DASHBOARD ROUTE:/g,
  /FCM:/g,
  /📱 FCM Notification would be sent/g,
  /✅ Email service initialized/g,
  /📧 Emails will be logged/g,
  /Avatar file validation/g,
  /Avatar extension test/g,
  /Avatar mimetype test/g,
  /Document file validation/g,
  /Document extension test/g
];

function processFile(filePath) {
  try {
    const fullPath = path.join(__dirname, '..', filePath);
    
    if (!fs.existsSync(fullPath)) {
      console.log(`File not found: ${filePath}`);
      return;
    }

    let content = fs.readFileSync(fullPath, 'utf8');
    let originalContent = content;
    let changes = 0;

    // Comment out debug patterns
    debugPatterns.forEach(pattern => {
      const matches = content.match(pattern);
      if (matches) {
        // Comment out lines containing debug patterns
        content = content.replace(
          new RegExp(`^\\s*(${pattern.source.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}.*)$`, 'gm'),
          '// $1'
        );
        changes += matches.length;
      }
    });

    // Remove specific debug blocks
    content = content.replace(
      /\/\/ console\.log\(.*?\);?\s*\n/g,
      ''
    );

    // Remove empty lines after commenting
    content = content.replace(/\n\s*\n\s*\n/g, '\n\n');

    if (content !== originalContent) {
      fs.writeFileSync(fullPath, content, 'utf8');
      console.log(`✅ Processed ${filePath} (${changes} changes)`);
    } else {
      console.log(`⏭️  No changes needed for ${filePath}`);
    }

  } catch (error) {
    console.error(`❌ Error processing ${filePath}:`, error.message);
  }
}

function main() {
  console.log('🧹 Cleaning up debug logs for production...\n');

  filesToProcess.forEach(file => {
    processFile(file);
  });

  console.log('\n✅ Debug log cleanup completed!');
  console.log('📝 Debug logs have been commented out or removed.');
  console.log('🔧 To restore debug logs, run: npm run restore-debug-logs');
}

if (require.main === module) {
  main();
}

module.exports = { processFile, debugPatterns }; 