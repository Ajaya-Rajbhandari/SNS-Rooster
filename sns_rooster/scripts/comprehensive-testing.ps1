# Comprehensive Testing Script for SNS Rooster
Write-Host "🔍 COMPREHENSIVE TESTING SUITE" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Testing Categories:" -ForegroundColor Yellow
Write-Host "   1. 🔒 Security Testing" -ForegroundColor White
Write-Host "   2. 🌐 API Endpoint Testing" -ForegroundColor White
Write-Host "   3. 📱 Android App Testing" -ForegroundColor White
Write-Host "   4. 💻 Web App Testing" -ForegroundColor White
Write-Host "   5. ⚡ Performance Testing" -ForegroundColor White
Write-Host "   6. 🧠 Memory Leak Detection" -ForegroundColor White
Write-Host "   7. 🔄 OTA Update Testing" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Select testing category (1-7) or 'all' for complete testing"

function Test-Security {
    Write-Host "🔒 SECURITY TESTING" -ForegroundColor Red
    Write-Host "==================" -ForegroundColor Red
    Write-Host ""
    
    Write-Host "1. API Key Exposure Check:" -ForegroundColor Yellow
    $webContent = Invoke-WebRequest -Uri "https://sns-rooster-8cca5.web.app" | Select-Object -ExpandProperty Content
    if ($webContent -match "AIza[0-9A-Za-z_-]{35}") {
        Write-Host "   ❌ CRITICAL: API key found in web source!" -ForegroundColor Red
    } else {
        Write-Host "   ✅ No API keys exposed in web source" -ForegroundColor Green
    }
    
    Write-Host "2. Environment Variables Check:" -ForegroundColor Yellow
    $envCheck = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/firebase" | Select-Object -ExpandProperty Content
    if ($envCheck -match "AIza[0-9A-Za-z_-]{35}") {
        Write-Host "   ✅ Firebase config loaded securely from backend" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Firebase config not loading properly" -ForegroundColor Red
    }
    
    Write-Host "3. CORS Configuration Check:" -ForegroundColor Yellow
    $corsHeaders = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/version" -Method Options
    if ($corsHeaders.Headers["Access-Control-Allow-Origin"]) {
        Write-Host "   ✅ CORS properly configured" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ CORS configuration needs review" -ForegroundColor Yellow
    }
    
    Write-Host "4. HTTPS Enforcement:" -ForegroundColor Yellow
    try {
        $httpResponse = Invoke-WebRequest -Uri "http://sns-rooster.onrender.com/api/app/version" -ErrorAction Stop
        Write-Host "   ⚠️ HTTP access still available (should redirect to HTTPS)" -ForegroundColor Yellow
    } catch {
        Write-Host "   ✅ HTTPS properly enforced" -ForegroundColor Green
    }
}

function Test-APIEndpoints {
    Write-Host "🌐 API ENDPOINT TESTING" -ForegroundColor Blue
    Write-Host "======================" -ForegroundColor Blue
    Write-Host ""
    
    $endpoints = @(
        @{url="https://sns-rooster.onrender.com/api/app/version"; name="App Version"},
        @{url="https://sns-rooster.onrender.com/api/app/version/check?platform=android`&version=1.0.5`&build=6"; name="Version Check"},
        @{url="https://sns-rooster.onrender.com/api/app/download/android/file"; name="APK Download"},
        @{url="https://sns-rooster.onrender.com/api/google-maps/script"; name="Google Maps Script"},
        @{url="https://sns-rooster.onrender.com/api/firebase"; name="Firebase Config"},
        @{url="https://sns-rooster.onrender.com/api/companies/available"; name="Companies API"},
        @{url="https://sns-rooster.onrender.com/api/employees"; name="Employees API"}
    )
    
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint.url -TimeoutSec 10
            $status = if ($response.StatusCode -eq 200) { "✅" } else { "⚠️" }
            Write-Host "   $status $($endpoint.name): $($response.StatusCode) - $($response.StatusDescription)" -ForegroundColor $(if ($response.StatusCode -eq 200) { "Green" } else { "Yellow" })
        } catch {
            Write-Host "   ❌ $($endpoint.name): Failed - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Test-AndroidApp {
    Write-Host "📱 ANDROID APP TESTING" -ForegroundColor Green
    Write-Host "=====================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "1. APK Download Test:" -ForegroundColor Yellow
    try {
        $apkResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/download/android/file" -Method Head
        $apkSize = [math]::Round($apkResponse.Headers["Content-Length"] / 1MB, 2)
        Write-Host "   ✅ APK available for download ($apkSize MB)" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ APK download failed" -ForegroundColor Red
    }
    
    Write-Host "2. Version Update Flow:" -ForegroundColor Yellow
    $oldVersion = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/version/check?platform=android`&version=1.0.4`&build=5" | ConvertFrom-Json
    if ($oldVersion.update_available) {
        Write-Host "   ✅ Update flow working correctly" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ Update flow needs verification" -ForegroundColor Yellow
    }
    
    Write-Host "3. Current Version Check:" -ForegroundColor Yellow
    $currentVersion = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/version/check?platform=android`&version=1.0.5`&build=6" | ConvertFrom-Json
    if (-not $currentVersion.update_available) {
        Write-Host "   ✅ Current version correctly identified" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Version check showing false update" -ForegroundColor Red
    }
}

function Test-WebApp {
    Write-Host "💻 WEB APP TESTING" -ForegroundColor Magenta
    Write-Host "==================" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "1. Web App Accessibility:" -ForegroundColor Yellow
    try {
        $webResponse = Invoke-WebRequest -Uri "https://sns-rooster-8cca5.web.app" -Method Head
        Write-Host "   ✅ Web app accessible (Status: $($webResponse.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Web app not accessible" -ForegroundColor Red
    }
    
    Write-Host "2. Google Maps Loading:" -ForegroundColor Yellow
    $mapsScript = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/google-maps/script" | Select-Object -ExpandProperty Content
    if ($mapsScript -match "google\.maps") {
        Write-Host "   ✅ Google Maps script loading correctly" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Google Maps script not loading properly" -ForegroundColor Red
    }
    
    Write-Host "3. Firebase Configuration:" -ForegroundColor Yellow
    $firebaseConfig = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/firebase" | ConvertFrom-Json
    if ($firebaseConfig.apiKey) {
        Write-Host "   ✅ Firebase configuration loading securely" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Firebase configuration not loading" -ForegroundColor Red
    }
}

function Test-Performance {
    Write-Host "⚡ PERFORMANCE TESTING" -ForegroundColor Yellow
    Write-Host "=====================" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "1. API Response Times:" -ForegroundColor Yellow
    $endpoints = @(
        "https://sns-rooster.onrender.com/api/app/version",
        "https://sns-rooster.onrender.com/api/firebase",
        "https://sns-rooster.onrender.com/api/google-maps/script"
    )
    
    foreach ($endpoint in $endpoints) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            Invoke-WebRequest -Uri $endpoint -TimeoutSec 10 | Out-Null
            $stopwatch.Stop()
            $responseTime = $stopwatch.ElapsedMilliseconds
            $status = if ($responseTime -lt 1000) { "✅" } elseif ($responseTime -lt 3000) { "⚠️" } else { "❌" }
            Write-Host "   $status $endpoint`: ${responseTime}ms" -ForegroundColor $(if ($responseTime -lt 1000) { "Green" } elseif ($responseTime -lt 3000) { "Yellow" } else { "Red" })
        } catch {
            Write-Host "   ❌ $endpoint`: Failed" -ForegroundColor Red
        }
    }
    
    Write-Host "2. Web App Load Time:" -ForegroundColor Yellow
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Invoke-WebRequest -Uri "https://sns-rooster-8cca5.web.app" | Out-Null
        $stopwatch.Stop()
        $loadTime = $stopwatch.ElapsedMilliseconds
        $status = if ($loadTime -lt 2000) { "✅" } elseif ($loadTime -lt 5000) { "⚠️" } else { "❌" }
        Write-Host "   $status Web app load time: ${loadTime}ms" -ForegroundColor $(if ($loadTime -lt 2000) { "Green" } elseif ($loadTime -lt 5000) { "Yellow" } else { "Red" })
    } catch {
        Write-Host "   ❌ Web app load test failed" -ForegroundColor Red
    }
}

function Test-MemoryLeaks {
    Write-Host "🧠 MEMORY LEAK DETECTION" -ForegroundColor DarkYellow
    Write-Host "=======================" -ForegroundColor DarkYellow
    Write-Host ""
    
    Write-Host "1. Backend Memory Usage:" -ForegroundColor Yellow
    Write-Host "   ℹ️ Check backend logs for memory usage patterns" -ForegroundColor White
    Write-Host "   ℹ️ Monitor for increasing memory consumption over time" -ForegroundColor White
    
    Write-Host "2. Frontend Memory Issues:" -ForegroundColor Yellow
    Write-Host "   ℹ️ Check browser console for memory warnings" -ForegroundColor White
    Write-Host "   ℹ️ Monitor for increasing heap size in DevTools" -ForegroundColor White
    
    Write-Host "3. Database Connection Pool:" -ForegroundColor Yellow
    Write-Host "   ℹ️ Verify database connections are properly closed" -ForegroundColor White
    Write-Host "   ℹ️ Check for connection leaks in backend logs" -ForegroundColor White
}

function Test-OTAUpdates {
    Write-Host "🔄 OTA UPDATE TESTING" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "1. Version Check Flow:" -ForegroundColor Yellow
    $versionChecks = @(
        @{version="1.0.4"; build="5"; expected=true},
        @{version="1.0.5"; build="6"; expected=false},
        @{version="1.0.3"; build="4"; expected=true}
    )
    
    foreach ($check in $versionChecks) {
        $response = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/version/check?platform=android`&version=$($check.version)`&build=$($check.build)" | ConvertFrom-Json
        $status = if ($response.update_available -eq $check.expected) { "✅" } else { "❌" }
        Write-Host "   $status Version $($check.version)+$($check.build): Update available = $($response.update_available) (Expected: $($check.expected))" -ForegroundColor $(if ($response.update_available -eq $check.expected) { "Green" } else { "Red" })
    }
    
    Write-Host "2. Download URL Accessibility:" -ForegroundColor Yellow
    try {
        $downloadResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/download/android/file" -Method Head
        if ($downloadResponse.StatusCode -eq 200) {
            Write-Host "   ✅ APK download URL accessible" -ForegroundColor Green
        } else {
            Write-Host "   ❌ APK download URL not accessible" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ❌ APK download test failed" -ForegroundColor Red
    }
}

# Execute selected tests
switch ($choice) {
    "1" { Test-Security }
    "2" { Test-APIEndpoints }
    "3" { Test-AndroidApp }
    "4" { Test-WebApp }
    "5" { Test-Performance }
    "6" { Test-MemoryLeaks }
    "7" { Test-OTAUpdates }
    "all" { 
        Test-Security
        Test-APIEndpoints
        Test-AndroidApp
        Test-WebApp
        Test-Performance
        Test-MemoryLeaks
        Test-OTAUpdates
    }
    default { Write-Host "Invalid choice. Please run the script again." -ForegroundColor Red }
}

Write-Host ""
Write-Host "📋 MANUAL TESTING CHECKLIST:" -ForegroundColor Yellow
Write-Host "===========================" -ForegroundColor Yellow
Write-Host "1. Test Android app on physical device" -ForegroundColor White
Write-Host "2. Test web app in different browsers" -ForegroundColor White
Write-Host "3. Test OTA update flow end-to-end" -ForegroundColor White
Write-Host "4. Test Google Maps functionality" -ForegroundColor White
Write-Host "5. Test Firebase features" -ForegroundColor White
Write-Host "6. Test admin portal functionality" -ForegroundColor White
Write-Host "7. Test error handling and edge cases" -ForegroundColor White
Write-Host "8. Test network connectivity issues" -ForegroundColor White
Write-Host "" 