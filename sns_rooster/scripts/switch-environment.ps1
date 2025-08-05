# Environment Switch Script for SNS Rooster
Write-Host "🔄 SNS Rooster Environment Switcher" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Choose environment:" -ForegroundColor Yellow
Write-Host "1. Development (Local)" -ForegroundColor White
Write-Host "2. Production (Render)" -ForegroundColor White
Write-Host "3. Exit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1-3): "

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "🚀 Starting in DEVELOPMENT mode..." -ForegroundColor Green
        Write-Host "   API URL: http://192.168.1.80:5000/api" -ForegroundColor White
        Write-Host "   Backend: http://192.168.1.80:5000" -ForegroundColor White
        Write-Host ""
        
        # Start Flutter in development mode
        flutter run -d chrome --web-port=3000 --dart-define=ENVIRONMENT=development --dart-define=API_URL=http://192.168.1.80:5000/api
    }
    "2" {
        Write-Host ""
        Write-Host "🚀 Starting in PRODUCTION mode..." -ForegroundColor Green
        Write-Host "   API URL: https://sns-rooster.onrender.com/api" -ForegroundColor White
        Write-Host "   Backend: https://sns-rooster.onrender.com" -ForegroundColor White
        Write-Host ""
        
        # Start Flutter in production mode
        flutter run -d chrome --web-port=3000 --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api
    }
    "3" {
        Write-Host "Exiting..." -ForegroundColor Yellow
    }
    default {
        Write-Host "Invalid choice. Please enter 1, 2, or 3." -ForegroundColor Red
    }
} 