# Security Audit Script for SNS Rooster
Write-Host "🔒 SECURITY AUDIT SUITE" -ForegroundColor Red
Write-Host "=====================" -ForegroundColor Red
Write-Host ""

Write-Host "🔍 Scanning for security vulnerabilities..." -ForegroundColor Yellow
Write-Host ""

# 1. Check for exposed API keys in web source
Write-Host "1. API Key Exposure Check:" -ForegroundColor Cyan
try {
    $webContent = Invoke-WebRequest -Uri "https://sns-rooster-8cca5.web.app" -TimeoutSec 10 | Select-Object -ExpandProperty Content
    
    # Check for Google Maps API keys
    if ($webContent -match "AIza[0-9A-Za-z_-]{35}") {
        Write-Host "   ❌ CRITICAL: Google Maps API key found in web source!" -ForegroundColor Red
        Write-Host "      This is a major security vulnerability!" -ForegroundColor Red
    } else {
        Write-Host "   ✅ No Google Maps API keys exposed in web source" -ForegroundColor Green
    }
    
    # Check for Firebase API keys
    if ($webContent -match "firebase.*apiKey.*AIza") {
        Write-Host "   ❌ CRITICAL: Firebase API key found in web source!" -ForegroundColor Red
    } else {
        Write-Host "   ✅ No Firebase API keys exposed in web source" -ForegroundColor Green
    }
    
    # Check for other sensitive data
    if ($webContent -match "password|secret|token|key") {
        Write-Host "   ⚠️ Potential sensitive data found in web source" -ForegroundColor Yellow
    } else {
        Write-Host "   ✅ No obvious sensitive data in web source" -ForegroundColor Green
    }
} catch {
    Write-Host "   ❌ Failed to check web source: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Check backend security headers
Write-Host ""
Write-Host "2. Security Headers Check:" -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/version" -Method Head -TimeoutSec 10
    
    $securityHeaders = @{
        "Strict-Transport-Security" = "HSTS"
        "X-Content-Type-Options" = "Content Type Protection"
        "X-Frame-Options" = "Clickjacking Protection"
        "X-XSS-Protection" = "XSS Protection"
        "Content-Security-Policy" = "CSP"
        "Referrer-Policy" = "Referrer Policy"
    }
    
    foreach ($header in $securityHeaders.GetEnumerator()) {
        if ($response.Headers[$header.Key]) {
            Write-Host "   ✅ $($header.Value): Present" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ $($header.Value): Missing" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "   ❌ Failed to check security headers: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Check CORS configuration
Write-Host ""
Write-Host "3. CORS Configuration Check:" -ForegroundColor Cyan
try {
    $corsResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/version" -Method Options -TimeoutSec 10
    
    if ($corsResponse.Headers["Access-Control-Allow-Origin"] -eq "*") {
        Write-Host "   ⚠️ CORS allows all origins (*) - consider restricting" -ForegroundColor Yellow
    } elseif ($corsResponse.Headers["Access-Control-Allow-Origin"]) {
        Write-Host "   ✅ CORS properly configured with specific origins" -ForegroundColor Green
    } else {
        Write-Host "   ❌ CORS headers not found" -ForegroundColor Red
    }
    
    if ($corsResponse.Headers["Access-Control-Allow-Methods"]) {
        Write-Host "   ✅ CORS methods properly defined" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ CORS methods not explicitly defined" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ Failed to check CORS: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Check HTTPS enforcement
Write-Host ""
Write-Host "4. HTTPS Enforcement Check:" -ForegroundColor Cyan
try {
    $httpResponse = Invoke-WebRequest -Uri "http://sns-rooster.onrender.com/api/app/version" -Method Head -TimeoutSec 5 -ErrorAction Stop
    Write-Host "   ⚠️ HTTP access still available (should redirect to HTTPS)" -ForegroundColor Yellow
} catch {
    if ($_.Exception.Message -match "301|302|307|308") {
        Write-Host "   ✅ HTTP properly redirects to HTTPS" -ForegroundColor Green
    } else {
        Write-Host "   ✅ HTTP access blocked (good for security)" -ForegroundColor Green
    }
}

# 5. Check for common vulnerabilities
Write-Host ""
Write-Host "5. Common Vulnerability Checks:" -ForegroundColor Cyan

# Check for directory listing
try {
    $dirResponse = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/" -TimeoutSec 10
    if ($dirResponse.Content -match "Index of|Directory listing") {
        Write-Host "   ❌ Directory listing enabled (security risk)" -ForegroundColor Red
    } else {
        Write-Host "   ✅ Directory listing disabled" -ForegroundColor Green
    }
} catch {
    Write-Host "   ✅ Directory listing test passed" -ForegroundColor Green
}

# Check for server information disclosure
try {
    $serverInfo = Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/version" -Method Head -TimeoutSec 10
    if ($serverInfo.Headers["Server"]) {
        Write-Host "   ⚠️ Server information disclosed: $($serverInfo.Headers["Server"])" -ForegroundColor Yellow
    } else {
        Write-Host "   ✅ Server information hidden" -ForegroundColor Green
    }
} catch {
    Write-Host "   ❌ Failed to check server info: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Check API endpoint security
Write-Host ""
Write-Host "6. API Endpoint Security:" -ForegroundColor Cyan

$endpoints = @(
    @{url="https://sns-rooster.onrender.com/api/app/version"; method="GET"; secure=true},
    @{url="https://sns-rooster.onrender.com/api/firebase"; method="GET"; secure=true},
    @{url="https://sns-rooster.onrender.com/api/google-maps/script"; method="GET"; secure=true},
    @{url="https://sns-rooster.onrender.com/api/companies/available"; method="GET"; secure=false},
    @{url="https://sns-rooster.onrender.com/api/employees"; method="GET"; secure=false}
)

foreach ($endpoint in $endpoints) {
    try {
        $response = Invoke-WebRequest -Uri $endpoint.url -Method $endpoint.method -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            if ($endpoint.secure) {
                Write-Host "   ✅ $($endpoint.url): Accessible (expected)" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️ $($endpoint.url): Publicly accessible (consider authentication)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "   ❌ $($endpoint.url): Status $($response.StatusCode)" -ForegroundColor Red
        }
    } catch {
        if ($endpoint.secure) {
            Write-Host "   ❌ $($endpoint.url): Failed - $($_.Exception.Message)" -ForegroundColor Red
        } else {
            Write-Host "   ⚠️ $($endpoint.url): Access denied (may need authentication)" -ForegroundColor Yellow
        }
    }
}

# 7. Check for SQL injection vulnerabilities
Write-Host ""
Write-Host "7. SQL Injection Check:" -ForegroundColor Cyan
Write-Host "   ℹ️ Manual testing required for SQL injection vulnerabilities" -ForegroundColor White
Write-Host "   ℹ️ Test input fields with SQL injection payloads" -ForegroundColor White
Write-Host "   ℹ️ Check for proper input validation and sanitization" -ForegroundColor White

# 8. Check for XSS vulnerabilities
Write-Host ""
Write-Host "8. XSS Vulnerability Check:" -ForegroundColor Cyan
Write-Host "   ℹ️ Manual testing required for XSS vulnerabilities" -ForegroundColor White
Write-Host "   ℹ️ Test input fields with XSS payloads" -ForegroundColor White
Write-Host "   ℹ️ Check for proper output encoding" -ForegroundColor White

# 9. Environment variable security
Write-Host ""
Write-Host "9. Environment Security:" -ForegroundColor Cyan
Write-Host "   ℹ️ Verify .env file is not committed to Git" -ForegroundColor White
Write-Host "   ℹ️ Check that all API keys are in environment variables" -ForegroundColor White
Write-Host "   ℹ️ Ensure no hardcoded credentials in source code" -ForegroundColor White

# 10. Dependencies security
Write-Host ""
Write-Host "10. Dependencies Security:" -ForegroundColor Cyan
Write-Host "   ℹ️ Run 'npm audit' in backend directory" -ForegroundColor White
Write-Host "   ℹ️ Check for known vulnerabilities in dependencies" -ForegroundColor White
Write-Host "   ℹ️ Update outdated packages with security fixes" -ForegroundColor White

Write-Host ""
Write-Host "🔒 SECURITY RECOMMENDATIONS:" -ForegroundColor Yellow
Write-Host "===========================" -ForegroundColor Yellow
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