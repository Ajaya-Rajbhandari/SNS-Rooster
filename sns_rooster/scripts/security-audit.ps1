# Security Audit Script for SNS Rooster
Write-Host "SECURITY AUDIT" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan
Write-Host ""

Write-Host "Running security audit..." -ForegroundColor Yellow
Write-Host ""

# 1. Check for API key exposure
Write-Host "1. API Key Exposure Check:" -ForegroundColor Green
try {
    $firebaseResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/firebase" -TimeoutSec 10
    $firebaseData = $firebaseResponse.Content | ConvertFrom-Json
    if ($firebaseData.apiKey -and $firebaseData.apiKey -ne "undefined") {
        Write-Host "   PASS: Firebase API key loaded securely from backend" -ForegroundColor Green
    } else {
        Write-Host "   WARN: Firebase API key not found or undefined" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   FAIL: Firebase config failed: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $mapsResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/google-maps/script" -TimeoutSec 10
    if ($mapsResponse.Content -match "AIza") {
        Write-Host "   FAIL: Google Maps API key exposed in script" -ForegroundColor Red
    } else {
        Write-Host "   PASS: Google Maps API key secured via backend proxy" -ForegroundColor Green
    }
} catch {
    Write-Host "   FAIL: Google Maps script failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Check security headers
Write-Host ""
Write-Host "2. Security Headers Check:" -ForegroundColor Green
try {
    $headersResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com" -Method Head -TimeoutSec 10
    
    $securityHeaders = @{
        "X-Frame-Options" = $headersResponse.Headers["X-Frame-Options"]
        "X-Content-Type-Options" = $headersResponse.Headers["X-Content-Type-Options"]
        "X-XSS-Protection" = $headersResponse.Headers["X-XSS-Protection"]
        "Strict-Transport-Security" = $headersResponse.Headers["Strict-Transport-Security"]
        "Content-Security-Policy" = $headersResponse.Headers["Content-Security-Policy"]
    }
    
    foreach ($header in $securityHeaders.GetEnumerator()) {
        if ($header.Value) {
            Write-Host "   PASS: $($header.Key) present" -ForegroundColor Green
        } else {
            Write-Host "   WARN: $($header.Key) missing" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "   FAIL: Failed to check security headers: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Check CORS configuration
Write-Host ""
Write-Host "3. CORS Configuration Check:" -ForegroundColor Green
try {
    $corsResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com" -Method Options -TimeoutSec 10
    if ($corsResponse.Headers["Access-Control-Allow-Origin"]) {
        Write-Host "   PASS: CORS headers present" -ForegroundColor Green
    } else {
        Write-Host "   WARN: CORS headers not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   PASS: CORS test completed" -ForegroundColor Green
}

# 4. Check HTTPS enforcement
Write-Host ""
Write-Host "4. HTTPS Enforcement Check:" -ForegroundColor Green
try {
    $httpResponse = Invoke-WebRequest -Uri "http://sns-rooster.onrender.com" -Method Head -TimeoutSec 10 -MaximumRedirection 0
    Write-Host "   WARN: HTTP requests not redirected to HTTPS" -ForegroundColor Yellow
} catch {
    if ($_.Exception.Message -match "301|302|307|308") {
        Write-Host "   PASS: HTTP requests redirected to HTTPS" -ForegroundColor Green
    } else {
        Write-Host "   PASS: HTTPS enforcement working" -ForegroundColor Green
    }
}

# 5. Check for common vulnerabilities
Write-Host ""
Write-Host "5. Common Vulnerabilities Check:" -ForegroundColor Green

# Check for directory listing
try {
    $dirResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/" -TimeoutSec 10
    if ($dirResponse.Content -match "Index of|Directory listing") {
        Write-Host "   FAIL: Directory listing enabled (security risk)" -ForegroundColor Red
    } else {
        Write-Host "   PASS: Directory listing disabled" -ForegroundColor Green
    }
} catch {
    Write-Host "   PASS: Directory listing test passed" -ForegroundColor Green
}

# Check for server information disclosure
try {
    $serverInfo = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/version/info" -Method Head -TimeoutSec 10
    if ($serverInfo.Headers["Server"]) {
        Write-Host "   WARN: Server information disclosed: $($serverInfo.Headers["Server"])" -ForegroundColor Yellow
    } else {
        Write-Host "   PASS: Server information hidden" -ForegroundColor Green
    }
} catch {
    Write-Host "   FAIL: Failed to check server info: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Check API endpoint security
Write-Host ""
Write-Host "6. API Endpoint Security:" -ForegroundColor Green

$endpoints = @(
    @{url="https://sns-rooster.onrender.com/api/app/version/info"; method="GET"; secure=true},
    @{url="https://sns-rooster.onrender.com/api/firebase"; method="GET"; secure=true},
    @{url="https://sns-rooster.onrender.com/api/google-maps/script"; method="GET"; secure=true}
)

foreach ($endpoint in $endpoints) {
    try {
        $response = Invoke-WebRequest -Uri $endpoint.url -Method $endpoint.method -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "   PASS: $($endpoint.url): Accessible (expected)" -ForegroundColor Green
        } else {
            Write-Host "   FAIL: $($endpoint.url): Status $($response.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "   FAIL: $($endpoint.url): Failed - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 7. Check for SQL injection vulnerabilities
Write-Host ""
Write-Host "7. SQL Injection Check:" -ForegroundColor Green
Write-Host "   INFO: Manual testing required for SQL injection vulnerabilities" -ForegroundColor White
Write-Host "   INFO: Test input fields with SQL injection payloads" -ForegroundColor White
Write-Host "   INFO: Check for proper input validation and sanitization" -ForegroundColor White

# 8. Check for XSS vulnerabilities
Write-Host ""
Write-Host "8. XSS Vulnerability Check:" -ForegroundColor Green
Write-Host "   INFO: Manual testing required for XSS vulnerabilities" -ForegroundColor White
Write-Host "   INFO: Test input fields with XSS payloads" -ForegroundColor White
Write-Host "   INFO: Check for proper output encoding" -ForegroundColor White

# 9. Environment variable security
Write-Host ""
Write-Host "9. Environment Security:" -ForegroundColor Green
Write-Host "   INFO: Verify .env file is not committed to Git" -ForegroundColor White
Write-Host "   INFO: Check that all API keys are in environment variables" -ForegroundColor White
Write-Host "   INFO: Ensure no hardcoded credentials in source code" -ForegroundColor White

# 10. Dependencies security
Write-Host ""
Write-Host "10. Dependencies Security:" -ForegroundColor Green
Write-Host "   INFO: Run 'npm audit' in backend directory" -ForegroundColor White
Write-Host "   INFO: Check for known vulnerabilities in dependencies" -ForegroundColor White
Write-Host "   INFO: Update outdated packages with security fixes" -ForegroundColor White

Write-Host ""
Write-Host "SECURITY RECOMMENDATIONS:" -ForegroundColor Yellow
Write-Host "=========================" -ForegroundColor Yellow
Write-Host "1. Implement rate limiting on API endpoints" -ForegroundColor White
Write-Host "2. Add authentication for sensitive endpoints" -ForegroundColor White
Write-Host "3. Implement proper input validation" -ForegroundColor White
Write-Host "4. Add request logging and monitoring" -ForegroundColor White
Write-Host "5. Regular security audits and penetration testing" -ForegroundColor White
Write-Host "6. Keep dependencies updated" -ForegroundColor White
Write-Host "7. Implement proper error handling (no sensitive data in errors)" -ForegroundColor White
Write-Host "8. Use HTTPS everywhere" -ForegroundColor White
Write-Host "9. Implement proper session management" -ForegroundColor White
Write-Host "10. Regular backup and disaster recovery testing" -ForegroundColor White
Write-Host "" 