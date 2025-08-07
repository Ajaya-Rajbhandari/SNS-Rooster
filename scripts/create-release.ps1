# SNS Rooster Release Script
param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$true)]
    [string]$BuildNumber,
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseNotes = "Bug fixes and improvements"
)

Write-Host "🚀 Creating release v$Version (Build $BuildNumber)" -ForegroundColor Green

# Create release directory
$releaseDir = "releases/v$Version"
if (Test-Path $releaseDir) {
    Remove-Item $releaseDir -Recurse -Force
}
New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null

Write-Host "📁 Created release directory: $releaseDir" -ForegroundColor Green

# Update pubspec.yaml
$pubspecPath = "sns_rooster/pubspec.yaml"
if (Test-Path $pubspecPath) {
    $pubspecContent = Get-Content $pubspecPath -Raw
    $pubspecContent = $pubspecContent -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $Version+$BuildNumber"
    Set-Content $pubspecPath $pubspecContent
    Write-Host "✅ Updated pubspec.yaml" -ForegroundColor Green
}

# Create release notes
$releaseDate = Get-Date -Format "yyyy-MM-dd"
$releaseTime = Get-Date -Format "HH:mm:ss UTC"

$releaseNotesContent = "# SNS Rooster v$Version`n`n"
$releaseNotesContent += "**Release Date:** $releaseDate`n"
$releaseNotesContent += "**Build Number:** $BuildNumber`n`n"
$releaseNotesContent += "## 🚀 What's New`n`n"
$releaseNotesContent += "$ReleaseNotes`n`n"
$releaseNotesContent += "## 📱 Download`n`n"
$releaseNotesContent += "- **GitHub Release:** [Download APK](https://github.com/Ajaya-Rajbhandari/SNS-Rooster/releases/tag/v$Version)`n"
$releaseNotesContent += "- **Google Play Store:** [Download from Play Store](https://play.google.com/store/apps/details?id=com.snstech.sns_rooster)`n`n"
$releaseNotesContent += "## 🔧 Installation`n`n"
$releaseNotesContent += "1. Download the APK file`n"
$releaseNotesContent += "2. Enable 'Install from Unknown Sources' in your Android settings`n"
$releaseNotesContent += "3. Open the downloaded APK file`n"
$releaseNotesContent += "4. Follow the installation prompts`n`n"
$releaseNotesContent += "## 🐛 Bug Reports`n`n"
$releaseNotesContent += "- **Email:** support@snstechservices.com.au`n"
$releaseNotesContent += "- **GitHub:** [Create an issue](https://github.com/Ajaya-Rajbhandari/SNS-Rooster/issues)`n`n"
$releaseNotesContent += "---`n"
$releaseNotesContent += "*Generated on $releaseDate*"

$releaseNotesPath = "$releaseDir/RELEASE_NOTES.md"
Set-Content $releaseNotesPath $releaseNotesContent
Write-Host "✅ Release notes created" -ForegroundColor Green

# Create Git tag
git add .
git commit -m "Release v$Version (Build $BuildNumber) - $ReleaseNotes"
git tag -a "v$Version" -m "Release v$Version (Build $BuildNumber)"

Write-Host "✅ Git tag v$Version created" -ForegroundColor Green

# Update server version
$serverUrl = "https://sns-rooster.onrender.com/api/app/version/update"
$updateData = @{
    platform = "android"
    version = $Version
    build_number = $BuildNumber
    update_required = $false
    message = "SNS Rooster v$Version is now available!"
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri $serverUrl -Method POST -Body $updateData -ContentType "application/json"
    Write-Host "✅ Server version updated" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Failed to update server version: $_" -ForegroundColor Yellow
}

Write-Host "`n🎉 Release v$Version created successfully!" -ForegroundColor Green
Write-Host "📁 Release files in: $releaseDir" -ForegroundColor Cyan
Write-Host "🏷️ Git tag: v$Version" -ForegroundColor Cyan
Write-Host "`n📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. git push origin main --tags" -ForegroundColor White
Write-Host "2. Build APK and upload to GitHub Releases" -ForegroundColor White
Write-Host "3. Test the release" -ForegroundColor White 