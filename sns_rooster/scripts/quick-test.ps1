# Quick Test Script for SNS Rooster
Write-Host "QUICK TEST SUITE" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Running quick tests..." -ForegroundColor Yellow
Write-Host ""

# Test 1: Web App Accessibility
Write-Host "1. Testing Web App Accessibility:" -ForegroundColor Green
try {
    $webResponse = Invoke-WebRequest -Uri "https://sns-rooster-8cca5.web.app" -Method Head -TimeoutSec 10
    Write-Host "   PASS: Web app accessible (Status: $($webResponse.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "   FAIL: Web app not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Backend API
Write-Host ""
Write-Host "2. Testing Backend API:" -ForegroundColor Green
try {
    $apiInfoResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/version/info" -TimeoutSec 10
    Write-Host "   PASS: Backend API info endpoint working (Status: $($apiInfoResponse.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "   FAIL: Backend API info endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $apiCheckResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/version/check" -TimeoutSec 10
    Write-Host "   PASS: Backend API check endpoint working (Status: $($apiCheckResponse.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "   FAIL: Backend API check endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Google Maps Script
Write-Host ""
Write-Host "3. Testing Google Maps Script:" -ForegroundColor Green
try {
    $mapsResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/google-maps/script" -TimeoutSec 10
    if ($mapsResponse.Content -match "google\.maps") {
        Write-Host "   PASS: Google Maps script loading correctly" -ForegroundColor Green
    } else {
        Write-Host "   WARN: Google Maps script content unexpected" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   FAIL: Google Maps script failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Firebase Config
Write-Host ""
Write-Host "4. Testing Firebase Config:" -ForegroundColor Green
try {
    $firebaseResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/firebase" -TimeoutSec 10
    $firebaseData = $firebaseResponse.Content | ConvertFrom-Json
    if ($firebaseData.apiKey) {
        Write-Host "   PASS: Firebase config loading securely" -ForegroundColor Green
    } else {
        Write-Host "   WARN: Firebase config missing API key" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   FAIL: Firebase config failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Version Check
Write-Host ""
Write-Host "5. Testing Version Check:" -ForegroundColor Green
try {
    $versionUrl = "https://sns-rooster.onrender.com/api/app/version/check?platform=android`&version=1.0.5`&build=6"
    $versionResponse = Invoke-WebRequest -Uri $versionUrl -TimeoutSec 10
    $versionData = $versionResponse.Content | ConvertFrom-Json
    Write-Host "   PASS: Version check working (Current: $($versionData.current_version), Latest: $($versionData.latest_version))" -ForegroundColor Green
} catch {
    Write-Host "   FAIL: Version check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: APK Download
Write-Host ""
Write-Host "6. Testing APK Download:" -ForegroundColor Green
try {
    $apkResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/download/android/file" -Method Head -TimeoutSec 10
    $apkSize = [math]::Round($apkResponse.Headers["Content-Length"] / 1MB, 2)
    Write-Host "   PASS: APK available for download ($apkSize MB)" -ForegroundColor Green
} catch {
    Write-Host "   FAIL: APK download failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "QUICK TEST COMPLETE!" -ForegroundColor Green
Write-Host "====================" -ForegroundColor Green
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "===========" -ForegroundColor Yellow
Write-Host "1. Run .\scripts\security-audit.ps1 for security testing" -ForegroundColor White
Write-Host "2. Run .\scripts\performance-monitor.ps1 for performance testing" -ForegroundColor White
Write-Host "3. Run .\scripts\manual-testing-checklist.ps1 for comprehensive manual testing" -ForegroundColor White
Write-Host ""

Write-Host "For comprehensive testing, use the other testing scripts:" -ForegroundColor Cyan
Write-Host "   - comprehensive-testing.ps1 (full automated testing)" -ForegroundColor White
Write-Host "   - security-audit.ps1 (security vulnerability scanning)" -ForegroundColor White
Write-Host "   - performance-monitor.ps1 (performance and load testing)" -ForegroundColor White
Write-Host "   - manual-testing-checklist.ps1 (step-by-step manual testing)" -ForegroundColor White
Write-Host "" 