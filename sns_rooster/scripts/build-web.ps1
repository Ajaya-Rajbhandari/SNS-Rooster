# SNS Rooster Web Build Script (PowerShell)
# This script builds the Flutter web app with secure environment variables

Write-Host "🔐 Building SNS Rooster Web App with secure configuration..." -ForegroundColor Green

# Check if environment variables are set
if (-not $env:API_URL) {
    Write-Host "❌ Error: API_URL environment variable is not set" -ForegroundColor Red
    exit 1
}

if (-not $env:FIREBASE_API_KEY) {
    Write-Host "❌ Error: FIREBASE_API_KEY environment variable is not set" -ForegroundColor Red
    exit 1
}

if (-not $env:GOOGLE_MAPS_API_KEY) {
    Write-Host "❌ Error: GOOGLE_MAPS_API_KEY environment variable is not set" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Environment variables validated" -ForegroundColor Green

# Build Flutter web app with environment variables
$buildCommand = @(
    "flutter", "build", "web",
    "--dart-define=API_URL=$env:API_URL",
    "--dart-define=FIREBASE_API_KEY=$env:FIREBASE_API_KEY",
    "--dart-define=FIREBASE_PROJECT_ID=$env:FIREBASE_PROJECT_ID",
    "--dart-define=FIREBASE_MESSAGING_SENDER_ID=$env:FIREBASE_MESSAGING_SENDER_ID",
    "--dart-define=FIREBASE_APP_ID=$env:FIREBASE_APP_ID",
    "--dart-define=GOOGLE_MAPS_API_KEY=$env:GOOGLE_MAPS_API_KEY",
    "--dart-define=ENVIRONMENT=$env:ENVIRONMENT",
    "--dart-define=APP_NAME=$env:APP_NAME",
    "--dart-define=APP_VERSION=$env:APP_VERSION",
    "--release"
)

& $buildCommand[0] $buildCommand[1..($buildCommand.Length-1)]

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Web app built successfully!" -ForegroundColor Green
    Write-Host "📁 Output: build/web/" -ForegroundColor Cyan
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
} 