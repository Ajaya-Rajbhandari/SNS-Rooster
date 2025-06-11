Write-Host "Testing Employee2 login..."

$body = '{"email":"employee2@snsrooster.com","password":"Employee@456"}'

try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method Post -Body $body -ContentType "application/json"
    Write-Host "Login successful!"
    Write-Host "Token present: $($response.token -ne $null)"
    Write-Host "User: $($response.user.name)"
    Write-Host "Role: $($response.user.role)"
} catch {
    Write-Host "Login failed!"
    Write-Host "Error: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        Write-Host "Status: $($_.Exception.Response.StatusCode)"
    }
}