#!/usr/bin/env node

/**
 * Disable Cancellation Restriction for Testing
 * Temporarily disables the 24-hour cancellation restriction
 */

const fs = require('fs');
const path = require('path');

const leaveControllerPath = path.join(__dirname, '../controllers/leave-controller.js');

async function disableCancellationRestriction() {
  try {
    console.log('🔧 Disabling 24-hour cancellation restriction for testing...');
    
    // Read the current file
    let content = fs.readFileSync(leaveControllerPath, 'utf8');
    
    // Check if already disabled
    if (content.includes('// TESTING: 24-hour restriction disabled')) {
      console.log('⚠️  Restriction already disabled for testing');
      return;
    }
    
    // Find and comment out the 24-hour check
    const restrictionPattern = /\/\/ Check if leave starts within 24 hours[\s\S]*?if \(hoursUntilLeave < 24\) \{[\s\S]*?return res\.status\(400\)\.json\(\{ message: 'Leave requests cannot be cancelled within 24 hours of start date\.' \}\);\s*\}/;
    
    if (restrictionPattern.test(content)) {
      // Replace with commented version
      content = content.replace(restrictionPattern, `// TESTING: 24-hour restriction disabled
    // // Check if leave starts within 24 hours
    // const now = new Date();
    // const leaveStart = new Date(leave.startDate);
    // const hoursUntilLeave = (leaveStart - now) / (1000 * 60 * 60);
    
    // if (hoursUntilLeave < 24) {
    //   return res.status(400).json({ message: 'Leave requests cannot be cancelled within 24 hours of start date.' });
    // }`);
      
      // Write back to file
      fs.writeFileSync(leaveControllerPath, content, 'utf8');
      console.log('✅ 24-hour cancellation restriction disabled for testing');
      console.log('📝 You can now cancel leave requests regardless of start time');
      console.log('⚠️  Remember to re-enable this restriction before production!');
    } else {
      console.log('❌ Could not find the 24-hour restriction code to disable');
    }
    
  } catch (error) {
    console.error('❌ Error disabling cancellation restriction:', error);
  }
}

async function enableCancellationRestriction() {
  try {
    console.log('🔧 Re-enabling 24-hour cancellation restriction...');
    
    // Read the current file
    let content = fs.readFileSync(leaveControllerPath, 'utf8');
    
    // Check if already enabled
    if (!content.includes('// TESTING: 24-hour restriction disabled')) {
      console.log('⚠️  Restriction already enabled');
      return;
    }
    
    // Find and uncomment the 24-hour check
    const commentedPattern = /\/\/ TESTING: 24-hour restriction disabled[\s\S]*?\/\/ \/\/ Check if leave starts within 24 hours[\s\S]*?\/\/ \/\/ if \(hoursUntilLeave < 24\) \{[\s\S]*?\/\/ \/\/ \}[\s\S]*?\/\/ \}/;
    
    if (commentedPattern.test(content)) {
      // Replace with uncommented version
      content = content.replace(commentedPattern, `    // Check if leave starts within 24 hours
    const now = new Date();
    const leaveStart = new Date(leave.startDate);
    const hoursUntilLeave = (leaveStart - now) / (1000 * 60 * 60);
    
    if (hoursUntilLeave < 24) {
      return res.status(400).json({ message: 'Leave requests cannot be cancelled within 24 hours of start date.' });
    }`);
      
      // Write back to file
      fs.writeFileSync(leaveControllerPath, content, 'utf8');
      console.log('✅ 24-hour cancellation restriction re-enabled');
      console.log('📝 Leave requests can no longer be cancelled within 24 hours of start date');
    } else {
      console.log('❌ Could not find the commented restriction code to enable');
    }
    
  } catch (error) {
    console.error('❌ Error enabling cancellation restriction:', error);
  }
}

// Check command line arguments
const command = process.argv[2];

if (command === 'enable') {
  enableCancellationRestriction();
} else if (command === 'disable') {
  disableCancellationRestriction();
} else {
  console.log('Usage:');
  console.log('  node scripts/disable-cancellation-restriction.js disable  # Disable 24-hour restriction for testing');
  console.log('  node scripts/disable-cancellation-restriction.js enable   # Re-enable 24-hour restriction');
  console.log('');
  console.log('⚠️  WARNING: Only disable for testing! Re-enable before production.');
}

module.exports = { disableCancellationRestriction, enableCancellationRestriction }; 