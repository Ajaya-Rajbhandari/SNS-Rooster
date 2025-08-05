# Performance Monitor Script for SNS Rooster
Write-Host "PERFORMANCE MONITOR" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Running performance tests..." -ForegroundColor Yellow
Write-Host ""

# 1. API Response Time Test
Write-Host "1. API Response Time Test:" -ForegroundColor Green

$endpoints = @(
    "https://sns-rooster.onrender.com/api/app/version/info",
    "https://sns-rooster.onrender.com/api/app/version/check?platform=android`&version=1.0.5`&build=6",
    "https://sns-rooster.onrender.com/api/firebase",
    "https://sns-rooster.onrender.com/api/google-maps/script"
)

$responseTimes = @()

foreach ($endpoint in $endpoints) {
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri $endpoint -TimeoutSec 30
        $stopwatch.Stop()
        $responseTime = $stopwatch.ElapsedMilliseconds
        
        $responseTimes += [PSCustomObject]@{
            Endpoint = $endpoint
            ResponseTime = $responseTime
            Status = $response.StatusCode
        }
        
        if ($responseTime -lt 1000) {
            Write-Host "   PASS: $endpoint - ${responseTime}ms (Excellent)" -ForegroundColor Green
        } elseif ($responseTime -lt 3000) {
            Write-Host "   PASS: $endpoint - ${responseTime}ms (Good)" -ForegroundColor Green
        } elseif ($responseTime -lt 5000) {
            Write-Host "   WARN: $endpoint - ${responseTime}ms (Slow)" -ForegroundColor Yellow
        } else {
            Write-Host "   FAIL: $endpoint - ${responseTime}ms (Very Slow)" -ForegroundColor Red
        }
    } catch {
        Write-Host "   FAIL: $endpoint - Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Calculate average response time
if ($responseTimes.Count -gt 0) {
    $avgResponseTime = ($responseTimes | Measure-Object -Property ResponseTime -Average).Average
    Write-Host ""
    Write-Host "   Average Response Time: ${avgResponseTime}ms" -ForegroundColor Cyan
}

# 2. Web App Load Time Test
Write-Host ""
Write-Host "2. Web App Load Time Test:" -ForegroundColor Green
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $webResponse = Invoke-WebRequest -Uri "https://sns-rooster-8cca5.web.app" -TimeoutSec 30
    $stopwatch.Stop()
    $loadTime = $stopwatch.ElapsedMilliseconds
    
    if ($loadTime -lt 2000) {
        Write-Host "   PASS: Web app loaded in ${loadTime}ms (Excellent)" -ForegroundColor Green
    } elseif ($loadTime -lt 5000) {
        Write-Host "   PASS: Web app loaded in ${loadTime}ms (Good)" -ForegroundColor Green
    } elseif ($loadTime -lt 10000) {
        Write-Host "   WARN: Web app loaded in ${loadTime}ms (Slow)" -ForegroundColor Yellow
    } else {
        Write-Host "   FAIL: Web app loaded in ${loadTime}ms (Very Slow)" -ForegroundColor Red
    }
} catch {
    Write-Host "   FAIL: Web app load test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Memory Usage Check (if backend is running locally)
Write-Host ""
Write-Host "3. Memory Usage Check:" -ForegroundColor Green
try {
    $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
    if ($nodeProcesses) {
        foreach ($process in $nodeProcesses) {
            $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
            Write-Host "   INFO: Node.js process (PID: $($process.Id)) using ${memoryMB}MB" -ForegroundColor White
        }
    } else {
        Write-Host "   INFO: No local Node.js processes found (backend may be running on Render)" -ForegroundColor White
    }
} catch {
    Write-Host "   INFO: Could not check memory usage" -ForegroundColor White
}

# 4. Basic Load Testing
Write-Host ""
Write-Host "4. Basic Load Testing:" -ForegroundColor Green

$loadTestEndpoint = "https://sns-rooster.onrender.com/api/app/version/info"
$concurrentRequests = 10
$successCount = 0
$failCount = 0
$totalTime = 0

Write-Host "   Testing $concurrentRequests concurrent requests..." -ForegroundColor White

$jobs = @()
for ($i = 1; $i -le $concurrentRequests; $i++) {
    $jobs += Start-Job -ScriptBlock {
        param($url)
        try {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 10
            $stopwatch.Stop()
            return @{
                Success = $true
                ResponseTime = $stopwatch.ElapsedMilliseconds
                Status = $response.StatusCode
            }
        } catch {
            return @{
                Success = $false
                Error = $_.Exception.Message
            }
        }
    } -ArgumentList $loadTestEndpoint
}

# Wait for all jobs to complete
Wait-Job -Job $jobs | Out-Null

# Collect results
foreach ($job in $jobs) {
    $result = Receive-Job -Job $job
    if ($result.Success) {
        $successCount++
        $totalTime += $result.ResponseTime
    } else {
        $failCount++
    }
}

# Clean up jobs
Remove-Job -Job $jobs

$successRate = [math]::Round(($successCount / $concurrentRequests) * 100, 2)
$avgLoadTime = if ($successCount -gt 0) { [math]::Round($totalTime / $successCount, 2) } else { 0 }

Write-Host "   Success Rate: ${successRate}% ($successCount/$concurrentRequests)" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })
Write-Host "   Average Response Time: ${avgLoadTime}ms" -ForegroundColor $(if ($avgLoadTime -lt 2000) { "Green" } elseif ($avgLoadTime -lt 5000) { "Yellow" } else { "Red" })

# 5. Database Connection Test (if accessible)
Write-Host ""
Write-Host "5. Database Connection Test:" -ForegroundColor Green
Write-Host "   INFO: Database connection test requires backend access" -ForegroundColor White
Write-Host "   INFO: Consider implementing health check endpoint for database status" -ForegroundColor White

# 6. File Upload Performance (if applicable)
Write-Host ""
Write-Host "6. File Upload Performance:" -ForegroundColor Green
Write-Host "   INFO: File upload testing requires authentication" -ForegroundColor White
Write-Host "   INFO: Test with various file sizes (1MB, 5MB, 10MB)" -ForegroundColor White

Write-Host ""
Write-Host "PERFORMANCE SUMMARY:" -ForegroundColor Yellow
Write-Host "===================" -ForegroundColor Yellow

# Performance recommendations based on results
Write-Host ""
Write-Host "PERFORMANCE RECOMMENDATIONS:" -ForegroundColor Yellow
Write-Host "============================" -ForegroundColor Yellow
Write-Host "1. Monitor response times regularly" -ForegroundColor White
Write-Host "2. Implement caching for frequently accessed data" -ForegroundColor White
Write-Host "3. Optimize database queries" -ForegroundColor White
Write-Host "4. Use CDN for static assets" -ForegroundColor White
Write-Host "5. Implement request compression" -ForegroundColor White
Write-Host "6. Monitor memory usage" -ForegroundColor White
Write-Host "7. Set up performance alerts" -ForegroundColor White
Write-Host "8. Set up performance dashboards" -ForegroundColor White
Write-Host ""

Write-Host "PERFORMANCE TEST COMPLETE!" -ForegroundColor Green
Write-Host "==========================" -ForegroundColor Green
Write-Host "" 