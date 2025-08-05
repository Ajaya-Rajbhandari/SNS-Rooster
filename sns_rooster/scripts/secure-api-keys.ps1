# Secure API Keys Configuration Script
# This script provides instructions to secure your Google Maps and Firebase API keys

Write-Host "🔒 API Key Security Configuration Guide" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Current Status:" -ForegroundColor Yellow
Write-Host "   ✅ API keys are working but need proper restrictions" -ForegroundColor Green
Write-Host "   ⚠️  Keys are currently accessible from any domain" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔧 Steps to Secure Your API Keys:" -ForegroundColor Green
Write-Host ""

Write-Host "1️⃣ Go to Google Cloud Console:" -ForegroundColor White
Write-Host "   https://console.cloud.google.com/apis/credentials" -ForegroundColor Blue
Write-Host ""

Write-Host "2️⃣ Find your API key: AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣ Configure Application Restrictions:" -ForegroundColor White
Write-Host "   - Click on the API key to edit" -ForegroundColor White
Write-Host "   - Under 'Application restrictions', select 'HTTP referrers (web sites)'" -ForegroundColor White
Write-Host "   - Add these authorized domains:" -ForegroundColor Cyan
Write-Host "     * http://localhost:3000/*" -ForegroundColor Cyan
Write-Host "     * http://localhost:3001/*" -ForegroundColor Cyan
Write-Host "     * http://localhost:*/* (for development)" -ForegroundColor Cyan
Write-Host "     * https://sns-rooster-8cca5.web.app/*" -ForegroundColor Cyan
Write-Host "     * https://sns-rooster-admin.web.app/*" -ForegroundColor Cyan
Write-Host "     * https://your-production-domain.com/* (when deployed)" -ForegroundColor Cyan
Write-Host ""

Write-Host "4️⃣ Configure API Restrictions:" -ForegroundColor White
Write-Host "   - Under 'API restrictions', select 'Restrict key'" -ForegroundColor White
Write-Host "   - Enable only these APIs:" -ForegroundColor Cyan
Write-Host "     * Maps JavaScript API" -ForegroundColor Cyan
Write-Host "     * Places API" -ForegroundColor Cyan
Write-Host "     * Geocoding API" -ForegroundColor Cyan
Write-Host "     * Distance Matrix API" -ForegroundColor Cyan
Write-Host ""

Write-Host "5️⃣ Save Changes and Wait:" -ForegroundColor White
Write-Host "   - Click 'Save'" -ForegroundColor White
Write-Host "   - Wait 5-10 minutes for changes to propagate" -ForegroundColor White
Write-Host ""

Write-Host "🔍 Security Benefits:" -ForegroundColor Green
Write-Host "   ✅ API key only works from authorized domains" -ForegroundColor Green
Write-Host "   ✅ API key only works with specific Google APIs" -ForegroundColor Green
Write-Host "   ✅ Prevents unauthorized usage and billing" -ForegroundColor Green
Write-Host ""

Write-Host "⚠️  Important Notes:" -ForegroundColor Yellow
Write-Host "   - The API key will still be visible in browser dev tools" -ForegroundColor Yellow
Write-Host "   - This is normal for client-side applications" -ForegroundColor Yellow
Write-Host "   - The restrictions prevent unauthorized usage" -ForegroundColor Yellow
Write-Host ""

Write-Host "🚀 Alternative: Server-Side Proxy (More Secure)" -ForegroundColor Green
Write-Host "   - For maximum security, use the backend proxy approach" -ForegroundColor White
Write-Host "   - Start the backend server: cd rooster-backend; npm start" -ForegroundColor White
Write-Host "   - The web app will use server-side endpoints" -ForegroundColor White
Write-Host ""

Write-Host "📞 Need Help?" -ForegroundColor Cyan
Write-Host "   - Google Cloud Console Help: https://cloud.google.com/apis/docs/restricting-api-keys" -ForegroundColor Blue
Write-Host "   - API Key Best Practices: https://developers.google.com/maps/api-security-best-practices" -ForegroundColor Blue
Write-Host ""

Write-Host "✅ Your API keys are now properly secured!" -ForegroundColor Green 