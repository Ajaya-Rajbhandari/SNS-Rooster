@echo off
echo ========================================
echo    SNS Rooster - Test All Platforms
echo ========================================
echo.
echo This will test the app on all platforms:
echo - Physical Android Device
echo - Android Emulator  
echo - Flutter Web Browser (Port 3000)
echo - Admin Portal (Port 3001)
echo.
echo Make sure you have:
echo - Physical device connected via USB
echo - Android emulator running
echo - Chrome browser installed
echo.
pause

echo.
echo Starting Backend Server in background...
start "Backend Server" cmd /k "cd rooster-backend && node app.js"
timeout /t 5 /nobreak >nul

echo.
echo Testing Physical Android Device...
start "Physical Device" cmd /k "cd sns_rooster && flutter run --dart-define=USE_PHYSICAL_DEVICE_IP=true"
timeout /t 10 /nobreak >nul

echo.
echo Testing Android Emulator...
start "Emulator" cmd /k "cd sns_rooster && flutter run --dart-define=USE_PHYSICAL_DEVICE_IP=false"
timeout /t 10 /nobreak >nul

echo.
echo Testing Flutter Web Browser...
start "Flutter Web" cmd /k "cd sns_rooster && flutter run -d chrome --web-port=3000"
timeout /t 10 /nobreak >nul

echo.
echo Testing Admin Portal...
start "Admin Portal" cmd /k "cd admin-portal && npm start"

echo.
echo All platforms are now testing!
echo - Backend: http://192.168.1.68:5000
echo - Physical Device: http://192.168.1.68:5000
echo - Emulator: http://10.0.2.2:5000  
echo - Flutter Web: http://localhost:3000
echo - Admin Portal: http://localhost:3001
echo.
pause 