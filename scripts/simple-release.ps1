# Simple SNS Rooster Release Script
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

# Ensure .gitignore excludes APK files
$gitignorePath = ".gitignore"
if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw
    if ($gitignoreContent -notmatch "\.apk") {
        Add-Content $gitignorePath "`n# APK files`n*.apk"
        Write-Host "✅ Added *.apk to .gitignore" -ForegroundColor Green
    }
} else {
    Set-Content $gitignorePath "# APK files`n*.apk"
    Write-Host "✅ Created .gitignore with *.apk exclusion" -ForegroundColor Green
}

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

$releaseNotesContent = @"
# SNS Rooster v$Version

**Release Date:** $releaseDate  
**Build Number:** $BuildNumber

## 🚀 What's New

$ReleaseNotes

## 📱 Download

- **GitHub Release:** [Download APK](https://github.com/Ajaya-Rajbhandari/SNS-Rooster/releases/tag/v$Version)
- **Google Play Store:** [Download from Play Store](https://play.google.com/store/apps/details?id=com.snstech.sns_rooster)

## 🔧 Installation

1. Download the APK file
2. Enable "Install from Unknown Sources" in your Android settings
3. Open the downloaded APK file
4. Follow the installation prompts

## 🐛 Bug Reports

- **Email:** support@snstechservices.com.au
- **GitHub:** [Create an issue](https://github.com/Ajaya-Rajbhandari/SNS-Rooster/issues)

---
*Generated on $releaseDate*
"@

$releaseNotesPath = "$releaseDir/RELEASE_NOTES.md"
Set-Content $releaseNotesPath $releaseNotesContent
Write-Host "✅ Release notes created" -ForegroundColor Green

# Create Git tag (excluding APK files)
git add .
git reset releases/v$Version/*.apk  # Exclude APK files from commit
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

Write-Host "`n📋 MANUAL UPLOAD WORKFLOW:" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow
Write-Host "1️⃣ Push to GitHub:" -ForegroundColor White
Write-Host "   git push origin main --tags" -ForegroundColor Cyan
Write-Host "`n2️⃣ Build APK:" -ForegroundColor White
Write-Host "   cd sns_rooster" -ForegroundColor Cyan
Write-Host "   flutter build apk --release" -ForegroundColor Cyan
Write-Host "   # APK will be in: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Gray
Write-Host "`n3️⃣ Upload to GitHub Releases:" -ForegroundColor White
Write-Host "   • Go to: https://github.com/Ajaya-Rajbhandari/SNS-Rooster/releases" -ForegroundColor Cyan
Write-Host "   • Click 'Edit' on release v$Version" -ForegroundColor Cyan
Write-Host "   • Drag & drop the APK file to 'Attach binaries'" -ForegroundColor Cyan
Write-Host "   • Click 'Update release'" -ForegroundColor Cyan
Write-Host "`n4️⃣ Test the release:" -ForegroundColor White
Write-Host "   • Download APK from GitHub release" -ForegroundColor Cyan
Write-Host "   • Install on test device" -ForegroundColor Cyan
Write-Host "   • Verify app shows v$Version" -ForegroundColor Cyan

Write-Host "`n⚠️ IMPORTANT NOTES:" -ForegroundColor Red
Write-Host "• APK files are excluded from Git to prevent LFS budget issues" -ForegroundColor White
Write-Host "• Manual upload to GitHub Releases is required" -ForegroundColor White
Write-Host "• This prevents deployment failures due to large files" -ForegroundColor White
Write-Host "• Users can download from GitHub, Play Store, or your server" -ForegroundColor White 