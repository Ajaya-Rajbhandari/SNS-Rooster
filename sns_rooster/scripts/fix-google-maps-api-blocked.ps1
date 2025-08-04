# Google Maps API Blocked Error Fix
# This script helps fix the "ApiTargetBlockedMapError"

Write-Host "🔧 Google Maps API Blocked Error Fix" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "❌ Current Error: ApiTargetBlockedMapError" -ForegroundColor Red
Write-Host "   This means your API key is blocked or has incorrect restrictions" -ForegroundColor Yellow
Write-Host ""

Write-Host "📋 Steps to Fix:" -ForegroundColor Green
Write-Host ""

Write-Host "1️⃣ Go to Google Cloud Console:" -ForegroundColor White
Write-Host "   https://console.cloud.google.com/" -ForegroundColor Blue
Write-Host ""

Write-Host "2️⃣ Select your project: sns-rooster-8cca5" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣ Navigate to APIs & Services > Credentials" -ForegroundColor White
Write-Host ""

Write-Host "4️⃣ Find your API key: AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor White
Write-Host "   Click on it to edit settings" -ForegroundColor White
Write-Host ""

Write-Host "5️⃣ Configure Application Restrictions:" -ForegroundColor White
Write-Host "   - Set to 'None' (recommended for development)" -ForegroundColor Green
Write-Host "   - OR set to 'HTTP referrers (web sites)' and add:" -ForegroundColor White
Write-Host "     * http://localhost:3000/*" -ForegroundColor Cyan
Write-Host "     * http://localhost:*/*" -ForegroundColor Cyan
Write-Host "     * http://127.0.0.1:*/*" -ForegroundColor Cyan
Write-Host ""

Write-Host "6️⃣ Configure API Restrictions:" -ForegroundColor White
Write-Host "   - Select 'Restrict key'" -ForegroundColor White
Write-Host "   - Enable these APIs:" -ForegroundColor Green
Write-Host "     * Maps JavaScript API" -ForegroundColor Cyan
Write-Host "     * Places API" -ForegroundColor Cyan
Write-Host "     * Geocoding API" -ForegroundColor Cyan
Write-Host ""

Write-Host "7️⃣ Enable Required APIs:" -ForegroundColor White
Write-Host "   Go to APIs & Services > Library and enable:" -ForegroundColor White
Write-Host "   - Maps JavaScript API" -ForegroundColor Cyan
Write-Host "   - Places API" -ForegroundColor Cyan
Write-Host "   - Geocoding API" -ForegroundColor Cyan
Write-Host ""

Write-Host "8️⃣ Check Billing:" -ForegroundColor White
Write-Host "   - Go to Billing in Google Cloud Console" -ForegroundColor White
Write-Host "   - Ensure billing is enabled for your project" -ForegroundColor Green
Write-Host ""

Write-Host "9️⃣ Save Changes and Wait:" -ForegroundColor White
Write-Host "   - Click 'Save' on API key settings" -ForegroundColor White
Write-Host "   - Wait 5-10 minutes for changes to propagate" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔄 After making changes:" -ForegroundColor Green
Write-Host "   - Refresh your web app" -ForegroundColor White
Write-Host "   - Clear browser cache (Ctrl+Shift+R)" -ForegroundColor White
Write-Host "   - Check browser console for errors" -ForegroundColor White
Write-Host ""

Write-Host "🔍 To verify the fix:" -ForegroundColor Cyan
Write-Host "   - Open browser developer tools (F12)" -ForegroundColor White
Write-Host "   - Check Console tab - should see no Google Maps errors" -ForegroundColor White
Write-Host "   - Map should load properly" -ForegroundColor White
Write-Host ""

Write-Host "⚠️  Security Note:" -ForegroundColor Yellow
Write-Host "   - For production, use proper domain restrictions" -ForegroundColor White
Write-Host "   - Never commit API keys to version control" -ForegroundColor White
Write-Host ""

Write-Host "✅ Expected Result:" -ForegroundColor Green
Write-Host "   - Google Maps loads without errors" -ForegroundColor White
Write-Host "   - No 'ApiTargetBlockedMapError' in console" -ForegroundColor White
Write-Host "   - Map markers and functionality work properly" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to continue..." 