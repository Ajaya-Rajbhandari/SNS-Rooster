# SNS Rooster Multi-App Startup Script
# This script starts all three applications: Backend, Flutter Web, and Admin Portal

Write-Host "🚀 Starting SNS Rooster Applications..." -ForegroundColor Green
Write-Host ""

# Function to check if a port is in use
function Test-Port {
    param([int]$Port)
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect("localhost", $Port)
        $connection.Close()
        return $true
    }
    catch {
        return $false
    }
}

# Check if required ports are available
Write-Host "🔍 Checking port availability..." -ForegroundColor Yellow

if (Test-Port -Port 5000) {
    Write-Host "❌ Port 5000 is already in use. Please stop any existing backend server." -ForegroundColor Red
    exit 1
}

if (Test-Port -Port 3000) {
    Write-Host "❌ Port 3000 is already in use. Please stop any existing Flutter web server." -ForegroundColor Red
    exit 1
}

if (Test-Port -Port 3001) {
    Write-Host "❌ Port 3001 is already in use. Please stop any existing admin portal server." -ForegroundColor Red
    exit 1
}

Write-Host "✅ All ports are available" -ForegroundColor Green
Write-Host ""

# Start Backend Server
Write-Host "🔧 Starting Backend Server (Port 5000)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd rooster-backend; npm run dev" -WindowStyle Normal

# Wait a moment for backend to start
Start-Sleep -Seconds 3

# Start Flutter Web App
Write-Host "📱 Starting Flutter Web App (Port 3000)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd sns_rooster; flutter run -d chrome --web-port 3000" -WindowStyle Normal

# Wait a moment for Flutter to start
Start-Sleep -Seconds 5

# Start Admin Portal
Write-Host "🖥️  Starting Admin Portal (Port 3001)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd admin-portal; npm start" -WindowStyle Normal

Write-Host ""
Write-Host "🎉 All applications are starting!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Application URLs:" -ForegroundColor Yellow
Write-Host "   • Backend API:     http://localhost:5000" -ForegroundColor White
Write-Host "   • Flutter Web App: http://localhost:3000" -ForegroundColor White
Write-Host "   • Admin Portal:    http://localhost:3001" -ForegroundColor White
Write-Host ""
Write-Host "⏳ Please wait for all applications to fully load..." -ForegroundColor Yellow
Write-Host "💡 You can close this window once all applications are running." -ForegroundColor Gray 