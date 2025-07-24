# Google Maps API Key Configuration Fix for Web
# This script provides instructions to fix the "RefererNotAllowedMapError"

Write-Host "🔧 Google Maps API Key Configuration Fix" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "❌ Current Issue: RefererNotAllowedMapError" -ForegroundColor Red
Write-Host "   Your site URL to be authorized: http://localhost:3000/" -ForegroundColor Yellow
Write-Host ""

Write-Host "📋 Steps to Fix:" -ForegroundColor Green
Write-Host ""

Write-Host "1️⃣ Go to Google Cloud Console:" -ForegroundColor White
Write-Host "   https://console.cloud.google.com/" -ForegroundColor Blue
Write-Host ""

Write-Host "2️⃣ Navigate to APIs & Services > Credentials" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣ Find your Google Maps API key and click on it" -ForegroundColor White
Write-Host ""

Write-Host "4️⃣ In the API key settings, scroll down to 'Application restrictions'" -ForegroundColor White
Write-Host "   - Make sure it's set to 'None' (which you already did)" -ForegroundColor Green
Write-Host ""

Write-Host "5️⃣ Scroll down to 'API restrictions'" -ForegroundColor White
Write-Host "   - Make sure 'Maps JavaScript API' is enabled" -ForegroundColor Green
Write-Host ""

Write-Host "6️⃣ ⚠️  IMPORTANT: Check 'HTTP referrers (web sites)' section" -ForegroundColor Yellow
Write-Host "   - If you see any referrer restrictions, you need to add:" -ForegroundColor White
Write-Host "     * http://localhost:3000/*" -ForegroundColor Cyan
Write-Host "     * http://localhost:*/*" -ForegroundColor Cyan
Write-Host "     * http://127.0.0.1:*/*" -ForegroundColor Cyan
Write-Host ""

Write-Host "7️⃣ Alternative: Set 'Application restrictions' to 'None'" -ForegroundColor White
Write-Host "   - This will allow all domains (less secure but easier for development)" -ForegroundColor Yellow
Write-Host ""

Write-Host "8️⃣ Click 'Save' and wait a few minutes for changes to propagate" -ForegroundColor White
Write-Host ""

Write-Host "🔄 After making changes:" -ForegroundColor Green
Write-Host "   - Refresh your web app" -ForegroundColor White
Write-Host "   - Clear browser cache if needed" -ForegroundColor White
Write-Host ""

Write-Host "🔍 To verify the fix:" -ForegroundColor Cyan
Write-Host "   - Open browser developer tools (F12)" -ForegroundColor White
Write-Host "   - Check the Console tab for any remaining Google Maps errors" -ForegroundColor White
Write-Host ""

Write-Host "📝 Note: If you're still having issues, try:" -ForegroundColor Yellow
Write-Host "   - Using a different browser" -ForegroundColor White
Write-Host "   - Clearing browser cache and cookies" -ForegroundColor White
Write-Host "   - Waiting 5-10 minutes for API key changes to take effect" -ForegroundColor White
Write-Host ""

Write-Host "✅ Expected Result:" -ForegroundColor Green
Write-Host "   - Google Maps should load properly on http://localhost:3000/" -ForegroundColor White
Write-Host "   - No more 'RefererNotAllowedMapError' in console" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to continue..." 