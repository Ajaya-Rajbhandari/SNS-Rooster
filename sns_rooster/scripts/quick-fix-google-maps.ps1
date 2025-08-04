# Quick Fix for Google Maps API Blocked Error
Write-Host "🚀 Quick Fix for Google Maps API Blocked Error" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

Write-Host "🔑 Your current API key: AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor Yellow
Write-Host ""

Write-Host "📋 IMMEDIATE STEPS TO FIX:" -ForegroundColor Cyan
Write-Host ""

Write-Host "1️⃣ Open Google Cloud Console:" -ForegroundColor White
Write-Host "   https://console.cloud.google.com/apis/credentials" -ForegroundColor Blue
Write-Host ""

Write-Host "2️⃣ Find your API key and click on it" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣ Set Application Restrictions to 'None'" -ForegroundColor Green
Write-Host "   (This will allow the API key to work from any domain)" -ForegroundColor White
Write-Host ""

Write-Host "4️⃣ Under API Restrictions, make sure these are enabled:" -ForegroundColor White
Write-Host "   ✅ Maps JavaScript API" -ForegroundColor Green
Write-Host "   ✅ Places API" -ForegroundColor Green
Write-Host "   ✅ Geocoding API" -ForegroundColor Green
Write-Host ""

Write-Host "5️⃣ Click 'Save'" -ForegroundColor White
Write-Host ""

Write-Host "6️⃣ Wait 2-3 minutes, then refresh your web app" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔍 If still not working, check:" -ForegroundColor Cyan
Write-Host "   - Billing is enabled for your project" -ForegroundColor White
Write-Host "   - APIs are enabled in the Library section" -ForegroundColor White
Write-Host ""

Write-Host "✅ Expected result: Google Maps loads without errors" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter when you've completed these steps..." 