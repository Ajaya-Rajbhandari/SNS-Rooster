# Performance Monitoring Script for SNS Rooster
Write-Host "⚡ PERFORMANCE MONITORING SUITE" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Yellow
Write-Host ""

Write-Host "📊 Monitoring performance metrics..." -ForegroundColor Cyan
Write-Host ""

# Configuration
$testCount = 10
$endpoints = @(
    @{url="https://sns-rooster.onrender.com/api/app/version"; name="App Version API"},
    @{url="https://sns-rooster.onrender.com/api/firebase"; name="Firebase Config API"},
    @{url="https://sns-rooster.onrender.com/api/google-maps/script"; name="Google Maps Script API"},
    @{url="https://sns-rooster.onrender.com/api/app/version/check?platform=android&version=1.0.5&build=6"; name="Version Check API"},
    @{url="https://sns-rooster-8cca5.web.app"; name="Web App Load"}
)

function Test-EndpointPerformance {
    param($endpoint)
    
    Write-Host "Testing $($endpoint.name)..." -ForegroundColor Yellow
    $responseTimes = @()
    $successCount = 0
    $errorCount = 0
    
    for ($i = 1; $i -le $testCount; $i++) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-WebRequest -Uri $endpoint.url -TimeoutSec 30
            $stopwatch.Stop()
            $responseTime = $stopwatch.ElapsedMilliseconds
            $responseTimes += $responseTime
            $successCount++
            
            Write-Host "   Test $i`: ${responseTime}ms (Status: $($response.StatusCode))" -ForegroundColor Green
        } catch {
            $stopwatch.Stop()
            $errorCount++
            Write-Host "   Test $i`: Failed - $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # Small delay between tests
        Start-Sleep -Milliseconds 100
    }
    
    if ($responseTimes.Count -gt 0) {
        $avgTime = [math]::Round(($responseTimes | Measure-Object -Average).Average, 2)
        $minTime = ($responseTimes | Measure-Object -Minimum).Minimum
        $maxTime = ($responseTimes | Measure-Object -Maximum).Maximum
        $successRate = [math]::Round(($successCount / $testCount) * 100, 1)
        
        Write-Host ""
        Write-Host "📈 $($endpoint.name) Performance Summary:" -ForegroundColor Cyan
        Write-Host "   Average Response Time: ${avgTime}ms" -ForegroundColor White
        Write-Host "   Min Response Time: ${minTime}ms" -ForegroundColor White
        Write-Host "   Max Response Time: ${maxTime}ms" -ForegroundColor White
        Write-Host "   Success Rate: ${successRate}%" -ForegroundColor White
        Write-Host "   Tests: $successCount/$testCount successful" -ForegroundColor White
        
        # Performance rating
        if ($avgTime -lt 500) {
            Write-Host "   🟢 Performance: Excellent" -ForegroundColor Green
        } elseif ($avgTime -lt 1000) {
            Write-Host "   🟡 Performance: Good" -ForegroundColor Yellow
        } elseif ($avgTime -lt 2000) {
            Write-Host "   🟠 Performance: Acceptable" -ForegroundColor DarkYellow
        } else {
            Write-Host "   🔴 Performance: Poor - needs optimization" -ForegroundColor Red
        }
    } else {
        Write-Host "   ❌ All tests failed for $($endpoint.name)" -ForegroundColor Red
    }
    
    Write-Host ""
    return @{
        Name = $endpoint.name
        AvgTime = if ($responseTimes.Count -gt 0) { [math]::Round(($responseTimes | Measure-Object -Average).Average, 2) } else { 0 }
        SuccessRate = [math]::Round(($successCount / $testCount) * 100, 1)
        ResponseTimes = $responseTimes
    }
}

# Run performance tests
$results = @()
foreach ($endpoint in $endpoints) {
    $result = Test-EndpointPerformance -endpoint $endpoint
    $results += $result
}

# Overall performance summary
Write-Host "📊 OVERALL PERFORMANCE SUMMARY" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

$workingEndpoints = $results | Where-Object { $_.SuccessRate -gt 0 }
if ($workingEndpoints.Count -gt 0) {
    $overallAvg = [math]::Round(($workingEndpoints.AvgTime | Measure-Object -Average).Average, 2)
    $overallSuccess = [math]::Round(($workingEndpoints.SuccessRate | Measure-Object -Average).Average, 1)
    
    Write-Host "Overall Average Response Time: ${overallAvg}ms" -ForegroundColor White
    Write-Host "Overall Success Rate: ${overallSuccess}%" -ForegroundColor White
    Write-Host ""
    
    # Performance recommendations
    Write-Host "🔧 PERFORMANCE RECOMMENDATIONS:" -ForegroundColor Yellow
    Write-Host "=============================" -ForegroundColor Yellow
    
    if ($overallAvg -gt 2000) {
        Write-Host "🔴 CRITICAL: Overall performance is poor" -ForegroundColor Red
        Write-Host "   - Consider server scaling" -ForegroundColor White
        Write-Host "   - Optimize database queries" -ForegroundColor White
        Write-Host "   - Implement caching" -ForegroundColor White
    } elseif ($overallAvg -gt 1000) {
        Write-Host "🟡 WARNING: Performance needs improvement" -ForegroundColor Yellow
        Write-Host "   - Consider implementing caching" -ForegroundColor White
        Write-Host "   - Optimize API responses" -ForegroundColor White
    } else {
        Write-Host "🟢 GOOD: Performance is acceptable" -ForegroundColor Green
        Write-Host "   - Continue monitoring" -ForegroundColor White
        Write-Host "   - Consider optimization for scale" -ForegroundColor White
    }
    
    # Identify slowest endpoints
    $slowestEndpoint = $workingEndpoints | Sort-Object AvgTime -Descending | Select-Object -First 1
    if ($slowestEndpoint.AvgTime -gt 1000) {
        Write-Host ""
        Write-Host "🐌 SLOWEST ENDPOINT: $($slowestEndpoint.Name)" -ForegroundColor Red
        Write-Host "   Average Time: $($slowestEndpoint.AvgTime)ms" -ForegroundColor White
        Write-Host "   Consider optimizing this endpoint" -ForegroundColor White
    }
} else {
    Write-Host "❌ No endpoints are working properly" -ForegroundColor Red
}

# Memory usage monitoring (if running locally)
Write-Host ""
Write-Host "🧠 MEMORY USAGE MONITORING" -ForegroundColor DarkYellow
Write-Host "=========================" -ForegroundColor DarkYellow

try {
    $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
    if ($nodeProcesses) {
        foreach ($process in $nodeProcesses) {
            $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
            Write-Host "   Node.js Process (PID: $($process.Id)): ${memoryMB}MB" -ForegroundColor White
            
            if ($memoryMB -gt 500) {
                Write-Host "   ⚠️ High memory usage detected" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "   ℹ️ No Node.js processes found (backend may not be running locally)" -ForegroundColor White
    }
} catch {
    Write-Host "   ℹ️ Memory monitoring not available" -ForegroundColor White
}

# Load testing simulation
Write-Host ""
Write-Host "🚀 LOAD TESTING SIMULATION" -ForegroundColor Magenta
Write-Host "=========================" -ForegroundColor Magenta

$loadTestCount = 20
Write-Host "Simulating $loadTestCount concurrent requests to version API..." -ForegroundColor Yellow

$loadTestResults = @()
$jobs = @()

for ($i = 1; $i -le $loadTestCount; $i++) {
    $job = Start-Job -ScriptBlock {
        param($url)
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 10
            $stopwatch.Stop()
            return @{
                Success = $true
                Time = $stopwatch.ElapsedMilliseconds
                Status = $response.StatusCode
            }
        } catch {
            $stopwatch.Stop()
            return @{
                Success = $false
                Time = $stopwatch.ElapsedMilliseconds
                Error = $_.Exception.Message
            }
        }
    } -ArgumentList "https://sns-rooster.onrender.com/api/app/version"
    
    $jobs += $job
}

# Wait for all jobs to complete
Wait-Job -Job $jobs | Out-Null

# Collect results
foreach ($job in $jobs) {
    $result = Receive-Job -Job $job
    $loadTestResults += $result
    Remove-Job -Job $job
}

$successfulLoadTests = $loadTestResults | Where-Object { $_.Success }
$failedLoadTests = $loadTestResults | Where-Object { -not $_.Success }

if ($successfulLoadTests.Count -gt 0) {
    $loadAvgTime = [math]::Round(($successfulLoadTests.Time | Measure-Object -Average).Average, 2)
    $loadSuccessRate = [math]::Round(($successfulLoadTests.Count / $loadTestCount) * 100, 1)
    
    Write-Host "   Load Test Results:" -ForegroundColor White
    Write-Host "   - Average Response Time: ${loadAvgTime}ms" -ForegroundColor White
    Write-Host "   - Success Rate: ${loadSuccessRate}%" -ForegroundColor White
    Write-Host "   - Failed Requests: $($failedLoadTests.Count)" -ForegroundColor White
    
    if ($loadSuccessRate -lt 90) {
        Write-Host "   ⚠️ Load test shows reliability issues" -ForegroundColor Yellow
    } else {
        Write-Host "   ✅ Load test passed successfully" -ForegroundColor Green
    }
} else {
    Write-Host "   ❌ All load tests failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 PERFORMANCE MONITORING CHECKLIST:" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow
Write-Host "1. Monitor response times regularly" -ForegroundColor White
Write-Host "2. Set up alerts for slow responses" -ForegroundColor White
Write-Host "3. Monitor server resource usage" -ForegroundColor White
Write-Host "4. Implement caching where appropriate" -ForegroundColor White
Write-Host "5. Optimize database queries" -ForegroundColor White
Write-Host "6. Consider CDN for static assets" -ForegroundColor White
Write-Host "7. Monitor error rates" -ForegroundColor White
Write-Host "8. Set up performance dashboards" -ForegroundColor White
Write-Host "" 