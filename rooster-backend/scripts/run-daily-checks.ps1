# Daily maintenance script for SNS Rooster app
# This script runs daily checks and notifications

param(
    [string]$Environment = "development"
)

# Set the working directory to the script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Log function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
    Add-Content -Path "daily-checks.log" -Value "[$timestamp] $Message"
}

Write-Log "Starting daily maintenance checks..."

try {
    # Check if Node.js is available
    $nodeVersion = node --version 2>$null
    if (-not $nodeVersion) {
        throw "Node.js is not installed or not in PATH"
    }
    Write-Log "Node.js version: $nodeVersion"

    # Run incomplete profile check
    Write-Log "Running incomplete profile check..."
    node check_incomplete_profiles.js
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Incomplete profile check completed successfully"
    } else {
        Write-Log "ERROR: Incomplete profile check failed with exit code $LASTEXITCODE"
    }

    # Add more daily checks here as needed
    # For example:
    # Write-Log "Running database cleanup..."
    # node cleanup_old_records.js
    
    Write-Log "Daily maintenance checks completed successfully"
    
} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
} 