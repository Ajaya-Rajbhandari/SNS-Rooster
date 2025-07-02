# Setup script for Windows Task Scheduler
# This script creates a scheduled task to run daily checks

param(
    [string]$TaskName = "SNS-Rooster-DailyChecks",
    [string]$Time = "09:00"
)

# Get the current script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DailyCheckScript = Join-Path $ScriptDir "run-daily-checks.ps1"

Write-Host "Setting up scheduled task for SNS Rooster daily checks..."
Write-Host "Script location: $DailyCheckScript"
Write-Host "Task will run daily at $Time"

# Check if the daily check script exists
if (-not (Test-Path $DailyCheckScript)) {
    Write-Error "Daily check script not found at: $DailyCheckScript"
    exit 1
}

# Create the scheduled task
try {
    # Remove existing task if it exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Removing existing task: $TaskName"
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # Create action
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$DailyCheckScript`""

    # Create trigger (daily at specified time)
    $trigger = New-ScheduledTaskTrigger -Daily -At $Time

    # Create settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    # Create principal to run as SYSTEM
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Create the task
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Daily maintenance checks for SNS Rooster application"

    # Register the task
    Register-ScheduledTask -TaskName $TaskName -InputObject $task

    Write-Host "✅ Scheduled task '$TaskName' created successfully!"
    Write-Host "The task will run daily at $Time"
    Write-Host ""
    Write-Host "To manage the task:"
    Write-Host "  - View: Get-ScheduledTask -TaskName '$TaskName'"
    Write-Host "  - Run manually: Start-ScheduledTask -TaskName '$TaskName'"
    Write-Host "  - Delete: Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
    Write-Host "  - Or use Task Scheduler GUI: taskschd.msc"

} catch {
    Write-Error "Failed to create scheduled task: $($_.Exception.Message)"
    exit 1
} 