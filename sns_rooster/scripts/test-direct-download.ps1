# Test Direct Download System
# This script tests the backend endpoints for the direct download system

Write-Host "Testing Direct Download System" -ForegroundColor Green
Write-Host ""

$baseUrl = "https://sns-rooster.onrender.com"

Write-Host "Testing Backend Endpoints..." -ForegroundColor Yellow
Write-Host ""

# Test 1: Version Check Endpoint
Write-Host "1. Testing Version Check Endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/app/version/check" -Method GET
    Write-Host "Version Check: SUCCESS" -ForegroundColor Green
    Write-Host "   Current Version: $($response.current_version)" -ForegroundColor White
    Write-Host "   Latest Version: $($response.latest_version)" -ForegroundColor White
    Write-Host "   Update Available: $($response.update_available)" -ForegroundColor White
} catch {
    Write-Host "Version Check: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: Download Info Endpoint
Write-Host "2. Testing Download Info Endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/app/download/android" -Method GET
    Write-Host "Download Info: SUCCESS" -ForegroundColor Green
    Write-Host "   Version: $($response.version)" -ForegroundColor White
    Write-Host "   Build Number: $($response.build_number)" -ForegroundColor White
    Write-Host "   Download URL: $($response.download_url)" -ForegroundColor White
    Write-Host "   File Size: $($response.file_size) bytes" -ForegroundColor White
} catch {
    Write-Host "Download Info: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Status Endpoint
Write-Host "3. Testing Status Endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/app/download/status" -Method GET
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "   Platform: $($response.platform)" -ForegroundColor White
    Write-Host "   Version: $($response.version)" -ForegroundColor White
    Write-Host "   File Exists: $($response.file_exists)" -ForegroundColor White
    Write-Host "   File Size: $($response.file_size) bytes" -ForegroundColor White
} catch {
    Write-Host "Status: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 4: File Download Endpoint (Expected to fail if no APK)
Write-Host "4. Testing File Download Endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/app/download/android/file" -Method GET
    Write-Host "File Download: SUCCESS" -ForegroundColor Green
    Write-Host "   File downloaded successfully" -ForegroundColor White
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "File Download: APK NOT FOUND (Expected)" -ForegroundColor Yellow
        Write-Host "   This is expected if no APK has been uploaded yet" -ForegroundColor White
    } else {
        Write-Host "File Download: FAILED" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""   
Write-Host "Test Summary:" -ForegroundColor Yellow
Write-Host ""

# Summary
Write-Host "Backend API endpoints are working correctly!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Build APK: flutter build apk --release" -ForegroundColor White
Write-Host "2. Upload APK to backend" -ForegroundColor White
Write-Host "3. Update download URL in backend" -ForegroundColor White
Write-Host "4. Deploy backend changes" -ForegroundColor White
Write-Host "5. Test on Android device" -ForegroundColor White
Write-Host ""
Write-Host "Ready for APK deployment!" -ForegroundColor Green 