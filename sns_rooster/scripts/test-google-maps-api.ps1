# Test Google Maps API Key Script
# This script tests if the Google Maps API key is working properly

param(
    [string]$ApiKey = "AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc"
)

Write-Host "🧪 Testing Google Maps API Key..." -ForegroundColor Yellow
Write-Host "API Key: $ApiKey" -ForegroundColor Cyan

# Test 1: Static Maps API (simplest test)
$staticMapUrl = "https://maps.googleapis.com/maps/api/staticmap?center=Sydney,Australia&zoom=13&size=400x400&key=$ApiKey"

Write-Host "`n📊 Test 1: Static Maps API" -ForegroundColor Green
Write-Host "URL: $staticMapUrl" -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri $staticMapUrl -Method GET
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Static Maps API: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "❌ Static Maps API: FAILED (Status: $($response.StatusCode))" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Static Maps API: ERROR - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Geocoding API
$geocodingUrl = "https://maps.googleapis.com/maps/api/geocode/json?address=Sydney&key=$ApiKey"

Write-Host "`n📍 Test 2: Geocoding API" -ForegroundColor Green
Write-Host "URL: $geocodingUrl" -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri $geocodingUrl -Method GET
    if ($response.StatusCode -eq 200) {
        $data = $response.Content | ConvertFrom-Json
        if ($data.status -eq "OK") {
            Write-Host "✅ Geocoding API: SUCCESS" -ForegroundColor Green
        } else {
            Write-Host "❌ Geocoding API: FAILED (Status: $($data.status))" -ForegroundColor Red
            Write-Host "Error: $($data.error_message)" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Geocoding API: FAILED (HTTP Status: $($response.StatusCode))" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Geocoding API: ERROR - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: JavaScript Maps API (simulate web usage)
Write-Host "`n🌐 Test 3: JavaScript Maps API" -ForegroundColor Green
Write-Host "This would be tested in a browser environment" -ForegroundColor Gray
Write-Host "Check if the API key has proper restrictions:" -ForegroundColor Yellow
Write-Host "  - HTTP referrers (web sites)" -ForegroundColor White
Write-Host "  - Android apps (package name)" -ForegroundColor White
Write-Host "  - iOS apps (bundle ID)" -ForegroundColor White

Write-Host "`n📋 Recommendations:" -ForegroundColor Cyan
Write-Host "1. Check Google Cloud Console for API key restrictions" -ForegroundColor White
Write-Host "2. Ensure Maps JavaScript API is enabled" -ForegroundColor White
Write-Host "3. Ensure Geocoding API is enabled" -ForegroundColor White
Write-Host "4. Check billing is enabled for the project" -ForegroundColor White
Write-Host "5. Verify API key restrictions allow your domains/apps" -ForegroundColor White 