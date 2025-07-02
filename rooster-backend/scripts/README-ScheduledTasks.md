# Scheduled Tasks Setup Guide

This guide explains how to set up automated daily maintenance tasks for the SNS Rooster application.

## Overview

The scheduled task will run daily checks for:
- Incomplete employee profiles
- Send notifications to admins and employees (one per day per user)
- Log all activities for monitoring

## Files

- `run-daily-checks.ps1` - Main script that runs the daily checks
- `setup-scheduled-task.ps1` - Script to create the Windows Task Scheduler task
- `check_incomplete_profiles.js` - Node.js script that checks for incomplete profiles
- `daily-checks.log` - Log file created by the daily checks script

## Setup Instructions

### 1. Run the Setup Script

Open PowerShell as Administrator and navigate to the scripts directory:

```powershell
cd "C:\Users\devcz\Desktop\Projects\SNS-Rooster-app\rooster-backend\scripts"
```

Run the setup script:

```powershell
.\setup-scheduled-task.ps1
```

By default, this will:
- Create a task named "SNS-Rooster-DailyChecks"
- Run daily at 9:00 AM
- Use SYSTEM account (runs even when no user is logged in)

### 2. Customize the Schedule (Optional)

To run at a different time:

```powershell
.\setup-scheduled-task.ps1 -Time "14:30"  # Run at 2:30 PM
```

To use a different task name:

```powershell
.\setup-scheduled-task.ps1 -TaskName "MyCustomTaskName"
```

### 3. Test the Setup

Test the daily checks script manually:

```powershell
.\run-daily-checks.ps1
```

Test the scheduled task manually:

```powershell
Start-ScheduledTask -TaskName "SNS-Rooster-DailyChecks"
```

## Managing the Task

### View Task Status
```powershell
Get-ScheduledTask -TaskName "SNS-Rooster-DailyChecks"
```

### Run Task Manually
```powershell
Start-ScheduledTask -TaskName "SNS-Rooster-DailyChecks"
```

### Delete Task
```powershell
Unregister-ScheduledTask -TaskName "SNS-Rooster-DailyChecks" -Confirm:$false
```

### Using Task Scheduler GUI
1. Press `Win + R`, type `taskschd.msc`, press Enter
2. Navigate to Task Scheduler Library
3. Find "SNS-Rooster-DailyChecks"
4. Right-click for options (Run, Properties, Delete, etc.)

## Monitoring

### Check Logs
The script creates a log file: `daily-checks.log`

View recent logs:
```powershell
Get-Content daily-checks.log -Tail 20
```

### Check Task History
1. Open Task Scheduler (`taskschd.msc`)
2. Find your task
3. Click "History" tab to see run history

## Troubleshooting

### Common Issues

1. **Task doesn't run**
   - Check if Node.js is installed and in PATH
   - Verify the script paths are correct
   - Check Windows Event Viewer for errors

2. **Permission errors**
   - Run setup script as Administrator
   - Ensure the task has proper permissions

3. **Script not found**
   - Verify all files are in the correct directory
   - Check file paths in the scripts

### Manual Testing

Test each component individually:

1. **Test Node.js script:**
   ```powershell
   node check_incomplete_profiles.js
   ```

2. **Test PowerShell wrapper:**
   ```powershell
   .\run-daily-checks.ps1
   ```

3. **Test scheduled task:**
   ```powershell
   Start-ScheduledTask -TaskName "SNS-Rooster-DailyChecks"
   ```

## Adding More Daily Checks

To add more daily maintenance tasks:

1. Create a new Node.js script (e.g., `cleanup_old_records.js`)
2. Add it to `run-daily-checks.ps1`:

```powershell
# Add this to run-daily-checks.ps1
Write-Log "Running cleanup..."
node cleanup_old_records.js
if ($LASTEXITCODE -eq 0) {
    Write-Log "Cleanup completed successfully"
} else {
    Write-Log "ERROR: Cleanup failed with exit code $LASTEXITCODE"
}
```

## Security Notes

- The task runs with SYSTEM privileges
- Ensure your scripts are secure and don't expose sensitive data
- Regularly review the log files
- Consider using a dedicated service account for production environments 