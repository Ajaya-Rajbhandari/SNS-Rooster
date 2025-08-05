# Development Mode Script
Write-Host "🚀 Starting SNS Rooster in DEVELOPMENT Mode" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

# Get current IP address for development
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" -or $_.IPAddress -like "172.*"} | Select-Object -First 1).IPAddress

if (-not $ipAddress) {
    $ipAddress = "localhost"
}

Write-Host "🔧 Environment Variables Set:" -ForegroundColor Yellow
Write-Host "   ENVIRONMENT: development" -ForegroundColor White
Write-Host "   API_URL: http://$ipAddress:5000/api" -ForegroundColor White
Write-Host "   API_HOST: $ipAddress" -ForegroundColor White
Write-Host ""

Write-Host "📱 Starting Flutter Web App..." -ForegroundColor Cyan
Write-Host "   URL: http://localhost:3000" -ForegroundColor White
Write-Host "   Backend: http://$ipAddress:5000" -ForegroundColor White
Write-Host ""

# Start Flutter web app in development mode
flutter run -d chrome --web-port=3000 --dart-define=ENVIRONMENT=development --dart-define=API_URL=http://$ipAddress:5000/api --dart-define=API_HOST=$ipAddress 