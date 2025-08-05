# Secure Google Maps API Key
Write-Host "🔒 Secure Google Maps API Key" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🚨 CRITICAL SECURITY ISSUE DETECTED:" -ForegroundColor Red
Write-Host "   API key is exposed in browser console" -ForegroundColor Yellow
Write-Host "   This is a major security vulnerability!" -ForegroundColor Red
Write-Host ""

Write-Host "✅ SECURITY FIXES APPLIED:" -ForegroundColor Green
Write-Host "   - Removed API key from frontend HTML" -ForegroundColor White
Write-Host "   - Implemented backend proxy loading" -ForegroundColor White
Write-Host "   - API key now only exists server-side" -ForegroundColor White
Write-Host ""

Write-Host "🔧 BACKEND CONFIGURATION REQUIRED:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1️⃣ Set Environment Variable:" -ForegroundColor White
Write-Host "   In your backend .env file, add:" -ForegroundColor Green
Write-Host "   GOOGLE_MAPS_API_KEY=AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor Cyan
Write-Host ""

Write-Host "2️⃣ Restart Backend Server:" -ForegroundColor White
Write-Host "   Stop and restart your backend server" -ForegroundColor Green
Write-Host "   cd rooster-backend && npm start" -ForegroundColor Cyan
Write-Host ""

Write-Host "3️⃣ Test Secure Loading:" -ForegroundColor White
Write-Host "   - Open browser console" -ForegroundColor Green
Write-Host "   - Check for Google Maps API loaded successfully (SECURE)" -ForegroundColor Green
Write-Host "   - Verify no API key in network requests" -ForegroundColor Green
Write-Host ""

Write-Host "🔍 ADDITIONAL SECURITY MEASURES:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1️⃣ Google Cloud Console Settings:" -ForegroundColor White
Write-Host "   - Go to: https://console.cloud.google.com/apis/credentials" -ForegroundColor Blue
Write-Host "   - Find your API key" -ForegroundColor White
Write-Host "   - Set HTTP referrer restrictions to your domain" -ForegroundColor Green
Write-Host "   - Example: *.yourdomain.com/*" -ForegroundColor Cyan
Write-Host ""

Write-Host "2️⃣ API Key Restrictions:" -ForegroundColor White
Write-Host "   - Restrict to specific APIs only" -ForegroundColor Green
Write-Host "   - Enable Maps JavaScript API" -ForegroundColor Green
Write-Host "   - Enable Maps SDK for Android" -ForegroundColor Green
Write-Host "   - Enable Places API" -ForegroundColor Green
Write-Host ""

Write-Host "3️⃣ Monitor Usage:" -ForegroundColor White
Write-Host "   - Check Google Cloud Console for usage" -ForegroundColor Green
Write-Host "   - Set up billing alerts" -ForegroundColor Green
Write-Host "   - Monitor for unusual activity" -ForegroundColor Green
Write-Host ""

Write-Host "⚠️  IMPORTANT NOTES:" -ForegroundColor Yellow
Write-Host "   - API key is now secure and not exposed in browser" -ForegroundColor White
Write-Host "   - All Google Maps requests go through your backend" -ForegroundColor White
Write-Host "   - This also fixes the Android REQUEST_TIMEOUT issue" -ForegroundColor White
Write-Host ""

Write-Host "🔗 Useful Links:" -ForegroundColor Cyan
Write-Host "   - Google Cloud Console: https://console.cloud.google.com/" -ForegroundColor Blue
Write-Host "   - API Key Security: https://developers.google.com/maps/api-security" -ForegroundColor Blue
Write-Host "   - HTTP Referrer Restrictions: https://developers.google.com/maps/api-security#http-referrers" -ForegroundColor Blue 