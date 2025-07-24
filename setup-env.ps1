# =============================================================================
# ENVIRONMENT SETUP SCRIPT
# =============================================================================
# This script helps you create the .env file with secure credentials

Write-Host "🔐 SNS Rooster Environment Setup" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Create the .env file content
$envContent = @"
# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================
# Replace with your new MongoDB connection string (after changing password)
MONGODB_URI=mongodb+srv://username:NEW_PASSWORD@cluster.mongodb.net/sns-rooster?retryWrites=true`&w=majority

# =============================================================================
# JWT CONFIGURATION
# =============================================================================
# Generate a new secure JWT secret (minimum 32 characters)
JWT_SECRET=your-new-super-secure-jwt-secret-here-minimum-32-characters

# =============================================================================
# FIREBASE CONFIGURATION
# =============================================================================
# Get new service account keys from Firebase Console
FIREBASE_PROJECT_ID=your-new-project-id
FIREBASE_PRIVATE_KEY=`"-----BEGIN PRIVATE KEY-----\nYour New Private Key Here\n-----END PRIVATE KEY-----\n`"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-new-project.iam.gserviceaccount.com

# =============================================================================
# EMAIL CONFIGURATION
# =============================================================================
EMAIL_PROVIDER=gmail
SMTP_HOST=smtp.gmail.com
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# =============================================================================
# GOOGLE MAPS CONFIGURATION
# =============================================================================
# Rotate your Google Maps API key
GOOGLE_MAPS_API_KEY=your-new-google-maps-api-key

# =============================================================================
# SERVER CONFIGURATION
# =============================================================================
PORT=5000
NODE_ENV=production

# =============================================================================
# CORS CONFIGURATION
# =============================================================================
# Add your production domains
ALLOWED_ORIGINS=https://your-production-domain.com,https://www.your-production-domain.com

# =============================================================================
# TESTING CONFIGURATION
# =============================================================================
# Password for test scripts (development only)
TEST_PASSWORD=your-test-password-for-development

# =============================================================================
# OPTIONAL: RESEND EMAIL SERVICE
# =============================================================================
# RESEND_API_KEY=your-resend-api-key
"@

# Save to .env file
$envContent | Out-File -FilePath "rooster-backend\.env" -Encoding UTF8

Write-Host "✅ Created rooster-backend\.env template" -ForegroundColor Green
Write-Host ""
Write-Host "📝 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Edit rooster-backend\.env and replace the placeholder values" -ForegroundColor White
Write-Host "2. Provide me with the values you want to use" -ForegroundColor White
Write-Host "3. I'll help you update the file with your secure credentials" -ForegroundColor White
Write-Host ""
Write-Host "🔐 SECURITY REMINDER:" -ForegroundColor Red
Write-Host "- Never commit .env files to git" -ForegroundColor White
Write-Host "- Use strong, unique passwords" -ForegroundColor White
Write-Host "- Rotate all exposed credentials" -ForegroundColor White 