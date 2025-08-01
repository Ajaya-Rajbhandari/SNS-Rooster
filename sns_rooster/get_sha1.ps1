# PowerShell script to get SHA-1 fingerprint for Android app
# Run this script from the project root directory

Write-Host "🔍 Getting SHA-1 Fingerprint for Android App" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Check if keytool is available
try {
    $keytoolVersion = keytool -version 2>&1
    Write-Host "✅ Keytool found" -ForegroundColor Green
} catch {
    Write-Host "❌ Keytool not found. Please install Java JDK and add it to PATH" -ForegroundColor Red
    exit 1
}

# Get debug keystore path
$debugKeystorePath = "$env:USERPROFILE\.android\debug.keystore"

if (Test-Path $debugKeystorePath) {
    Write-Host "📁 Debug keystore found at: $debugKeystorePath" -ForegroundColor Yellow
    
    # Get SHA-1 fingerprint
    Write-Host "🔑 Getting SHA-1 fingerprint..." -ForegroundColor Yellow
    
    try {
        $sha1Output = keytool -list -v -keystore $debugKeystorePath -alias androiddebugkey -storepass android -keypass android 2>&1
        
        # Extract SHA-1 from output
        $sha1Line = $sha1Output | Select-String "SHA1:"
        if ($sha1Line) {
            $sha1 = ($sha1Line -split "SHA1: ")[1].Trim()
            Write-Host "✅ SHA-1 Fingerprint: $sha1" -ForegroundColor Green
            Write-Host ""
            Write-Host "📋 Next Steps:" -ForegroundColor Cyan
            Write-Host "1. Go to Google Cloud Console" -ForegroundColor White
            Write-Host "2. Navigate to APIs & Services → Credentials" -ForegroundColor White
            Write-Host "3. Edit your Google Maps API key" -ForegroundColor White
            Write-Host "4. Add Android app restriction with:" -ForegroundColor White
            Write-Host "   - Package name: com.snstech.sns_rooster" -ForegroundColor White
            Write-Host "   - SHA-1: $sha1" -ForegroundColor White
            Write-Host ""
            Write-Host "💡 Copy the SHA-1 above and add it to Google Cloud Console" -ForegroundColor Yellow
        } else {
            Write-Host "❌ Could not extract SHA-1 from keytool output" -ForegroundColor Red
            Write-Host "Full output:" -ForegroundColor Red
            Write-Host $sha1Output -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Error running keytool: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Debug keystore not found at: $debugKeystorePath" -ForegroundColor Red
    Write-Host "💡 This usually means you haven't built the app yet." -ForegroundColor Yellow
    Write-Host "   Try running: flutter build apk --debug" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 