# Auto-Detect IP and Update Flutter Configuration
# This script automatically detects your current local IP address and updates the Flutter app configuration

param(
    [switch]$Force,
    [switch]$Verbose
)

Write-Host "SNS Rooster - Auto IP Detection & Configuration" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Function to get local IP address
function Get-LocalIPAddress {
    try {
        # Get all network adapters
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -notlike "*Loopback*" -and $_.InterfaceDescription -notlike "*Virtual*" }
        
        foreach ($adapter in $adapters) {
            $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 | Where-Object { 
                $_.IPAddress -notlike "127.*" -and 
                $_.IPAddress -notlike "169.254.*" -and
                ($_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" -or $_.IPAddress -like "172.*")
            }
            
            if ($ipConfig) {
                return $ipConfig.IPAddress
            }
        }
        
        # Fallback: try alternative method
        $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
            $_.IPAddress -notlike "127.*" -and 
            $_.IPAddress -notlike "169.254.*" -and
            ($_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" -or $_.IPAddress -like "172.*")
        } | Select-Object -First 1).IPAddress
        
        return $ip
    }
    catch {
        Write-Host "Error detecting IP address: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to update Flutter configuration
function Update-FlutterConfig {
    param([string]$IPAddress)
    
    $configFile = "sns_rooster\lib\config\api_config.dart"
    
    if (-not (Test-Path $configFile)) {
        Write-Host "Error: Configuration file not found at $configFile" -ForegroundColor Red
        Write-Host "   Make sure you're running this script from the project root directory" -ForegroundColor Yellow
        return $false
    }
    
    try {
        $content = Get-Content $configFile -Raw
        
        # Update the fallbackIP line
        $pattern = "static const String fallbackIP =\s*'[^']*'"
        $replacement = "static const String fallbackIP = '$IPAddress'"
        
        if ($content -match $pattern) {
            $newContent = $content -replace $pattern, $replacement
            Set-Content $configFile $newContent -Encoding UTF8
            
            Write-Host "Successfully updated fallbackIP to: $IPAddress" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Could not find fallbackIP pattern in configuration file" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error updating configuration: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test backend connectivity
function Test-BackendConnectivity {
    param([string]$IPAddress)
    
    $url = "http://$IPAddress:5000/api/auth/login"
    
    try {
        $response = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 404) {
            # 404 is expected for GET on login endpoint, but means server is reachable
            Write-Host "Backend server is reachable at $IPAddress:5000" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "Backend server not reachable at $IPAddress:5000" -ForegroundColor Yellow
        Write-Host "   Make sure the backend server is running: npm start" -ForegroundColor White
        return $false
    }
}

# Main execution
try {
    # Detect current IP
    Write-Host "Detecting your current local IP address..." -ForegroundColor Blue
    $currentIP = Get-LocalIPAddress
    
    if (-not $currentIP) {
        Write-Host "Could not detect local IP address" -ForegroundColor Red
        Write-Host "   Please check your network connection and try again" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Detected IP: $currentIP" -ForegroundColor Green
    
    # Check if backend is running
    Write-Host "Testing backend connectivity..." -ForegroundColor Blue
    $backendReachable = Test-BackendConnectivity -IPAddress $currentIP
    
    # Read current configuration
    $configFile = "sns_rooster\lib\config\api_config.dart"
    if (Test-Path $configFile) {
        $content = Get-Content $configFile -Raw
        if ($content -match "static const String fallbackIP = '([^']*)'") {
            $currentConfigIP = $matches[1]
            Write-Host "Current configuration IP: $currentConfigIP" -ForegroundColor Yellow
            
            if ($currentConfigIP -eq $currentIP -and -not $Force) {
                Write-Host "Configuration is already up to date!" -ForegroundColor Green
                Write-Host "   Use -Force to update anyway" -ForegroundColor White
            } else {
                # Update configuration
                Write-Host "Updating Flutter configuration..." -ForegroundColor Blue
                $success = Update-FlutterConfig -IPAddress $currentIP
                
                if ($success) {
                    Write-Host ""
                    Write-Host "Configuration Summary:" -ForegroundColor Cyan
                    Write-Host "   Detected IP: $currentIP" -ForegroundColor White
                    Write-Host "   Backend reachable: $(if ($backendReachable) { 'Yes' } else { 'No' })" -ForegroundColor White
                    Write-Host "   Configuration updated: Yes" -ForegroundColor White
                    
                    Write-Host ""
                    Write-Host "Next Steps:" -ForegroundColor Cyan
                    Write-Host "   1. Restart your Flutter app completely" -ForegroundColor White
                    Write-Host "   2. Make sure backend server is running: npm start" -ForegroundColor White
                    Write-Host "   3. Test the app on your physical device" -ForegroundColor White
                    
                    if (-not $backendReachable) {
                        Write-Host ""
                        Write-Host "Backend server is not reachable!" -ForegroundColor Yellow
                        Write-Host "   Start the backend server first:" -ForegroundColor White
                        Write-Host "   cd rooster-backend && npm start" -ForegroundColor Gray
                    }
                }
            }
        }
    }
    
    # Show detailed network info if verbose
    if ($Verbose) {
        Write-Host ""
        Write-Host "Detailed Network Information:" -ForegroundColor Cyan
        Write-Host "=================================" -ForegroundColor Cyan
        
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($adapter in $adapters) {
            Write-Host "Adapter: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor White
            $ips = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
            foreach ($ip in $ips) {
                $status = if ($ip.IPAddress -eq $currentIP) { "SELECTED" } else { "" }
                Write-Host "   $($ip.IPAddress) $status" -ForegroundColor Gray
            }
        }
    }
    
}
catch {
    Write-Host "Script execution failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Auto-detection completed!" -ForegroundColor Green 