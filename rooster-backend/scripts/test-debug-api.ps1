# Test script for debug API
$body = @{
    email = "testuser@example.com"
    password = "Test@123"
} | ConvertTo-Json

Write-Host "Testing debug API with body: $body"

try {
    $response = Invoke-RestMethod -Uri 'http://192.168.1.67:5001/api/auth/login' -Method POST -Body $body -ContentType 'application/json'
    Write-Host "Success: $($response | ConvertTo-Json -Depth 3)"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "Response: $($_.Exception.Response)"
}