const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const ENV_SECRET = process.env.JWT_SECRET;
const filesToCheck = [
  path.join(__dirname, '../generateToken.js'),
  path.join(__dirname, '../routes/authRoutes.js'),
  path.join(__dirname, '../middleware/auth.js'),
  path.join(__dirname, '../tests/employee_management.test.js'),
  path.join(__dirname, '../tests/employee_dashboard.test.js'),
  path.join(__dirname, '../scripts/debug-login.js'),
];

const issues = [];

filesToCheck.forEach((file) => {
  const content = fs.readFileSync(file, 'utf8');
  // Check for hardcoded secret
  const hardcodedSecretMatch = content.match(/(['\"])([a-f0-9]{64})\1/);
  if (hardcodedSecretMatch && hardcodedSecretMatch[2] !== ENV_SECRET) {
    issues.push(`${file}: Hardcoded secret does not match .env JWT_SECRET`);
  }
  // Check for fallback/default secret usage
  if (content.includes("process.env.JWT_SECRET || 'defaultSecret'") || content.includes('process.env.JWT_SECRET || "defaultSecret"')) {
    issues.push(`${file}: Uses fallback 'defaultSecret' which may cause inconsistency`);
  }
  if (content.includes("process.env.JWT_SECRET || 'fallback-secret'") || content.includes('process.env.JWT_SECRET || "fallback-secret"')) {
    issues.push(`${file}: Uses fallback 'fallback-secret' which may cause inconsistency`);
  }
});

if (issues.length === 0) {
  console.log('✅ All JWT secret usages are consistent with .env');
  process.exit(0);
} else {
  console.error('❌ JWT secret inconsistencies found:');
  issues.forEach((issue) => console.error(' -', issue));
  process.exit(1);
}