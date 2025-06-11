param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("home", "office")]
    [string]$Environment
)

# Configuration - Update these IPs based on your actual network setup
$homeIP = "192.168.1.67"    # Your home network IP
$officeIP = "10.0.0.45"     # Your office network IP (update this!)
$port = "5000"

Write-Host "🔄 SNS Rooster Environment Switcher" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

switch ($Environment) {
    "home" { 
        Write-Host "🏠 Switching to HOME environment" -ForegroundColor Green
        Write-Host "   Target IP: $homeIP" -ForegroundColor Yellow
        $targetIP = $homeIP
    }
    "office" { 
        Write-Host "🏢 Switching to OFFICE environment" -ForegroundColor Green
        Write-Host "   Target IP: $officeIP" -ForegroundColor Yellow
        $targetIP = $officeIP
    }
}

# Check if the Flutter project exists
$flutterProjectPath = "sns_rooster\lib\screens\admin\user_management_screen.dart"
if (-not (Test-Path $flutterProjectPath)) {
    Write-Host "❌ Error: Flutter project not found at $flutterProjectPath" -ForegroundColor Red
    Write-Host "   Make sure you're running this script from the project root directory" -ForegroundColor Yellow
    exit 1
}

try {
    # Update the user_management_screen.dart file
    Write-Host "📝 Updating API configuration..." -ForegroundColor Blue
    
    $content = Get-Content $flutterProjectPath -Raw
    $pattern = "final String _baseUrl = 'http://[^']+'"
    $replacement = "final String _baseUrl = 'http://$targetIP:$port/api'"
    $newContent = $content -replace $pattern, $replacement
    
    Set-Content $flutterProjectPath $newContent -Encoding UTF8
    
    Write-Host "✅ Successfully updated API URL to: http://$targetIP:$port/api" -ForegroundColor Green
    
    # Display next steps
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. 🔄 Restart your Flutter app completely" -ForegroundColor White
    Write-Host "   2. 🖥️  Make sure backend server is running: npm start or node server.js" -ForegroundColor White
    Write-Host "   3. 🧪 Test connectivity: node test-ip-connection.js" -ForegroundColor White
    Write-Host "   4. 📱 Hot reload your Flutter app" -ForegroundColor White
    
    Write-Host ""
    Write-Host "💡 Tip: Verify your current IP with 'ipconfig' if you encounter issues" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ Error updating configuration: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Environment switch completed!" -ForegroundColor Green