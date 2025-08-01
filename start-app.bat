@echo off
echo ========================================
echo    SNS Rooster App Launcher
echo ========================================
echo.
echo Choose an option:
echo 1. Start Backend Server Only
echo 2. Start Flutter App - Physical Android Device
echo 3. Start Flutter App - Android Emulator
echo 4. Start Flutter App - Web Browser (Port 3000)
echo 5. Start Admin Portal - Web Browser (Port 3001)
echo 6. Start Both (Backend + Physical Device)
echo 7. Start Both (Backend + Emulator)
echo 8. Start Both (Backend + Flutter Web)
echo 9. Start Both (Backend + Admin Portal)
echo 10. Exit
echo.
set /p choice="Enter your choice (1-10): "

if "%choice%"=="1" goto backend
if "%choice%"=="2" goto physical
if "%choice%"=="3" goto emulator
if "%choice%"=="4" goto web
if "%choice%"=="5" goto admin
if "%choice%"=="6" goto both_physical
if "%choice%"=="7" goto both_emulator
if "%choice%"=="8" goto both_web
if "%choice%"=="9" goto both_admin
if "%choice%"=="10" goto exit
goto invalid

:backend
echo.
echo Starting Backend Server...
echo Backend will be available at: http://192.168.1.119:5000
echo.
cd rooster-backend
node app.js
goto end

:physical
echo.
echo Starting Flutter App on Physical Android Device...
echo Connecting to backend at: http://192.168.1.80:5000
echo.
cd sns_rooster
flutter run --dart-define=USE_PHYSICAL_DEVICE_IP=true
goto end

:emulator
echo.
echo Starting Flutter App on Android Emulator...
echo Connecting to backend at: http://10.0.2.2:5000
echo.
cd sns_rooster
flutter run --dart-define=USE_PHYSICAL_DEVICE_IP=false
goto end

:web
echo.
echo Starting Flutter App on Web Browser...
echo Connecting to backend at: http://localhost:5000
echo Web app will be available at: http://localhost:3000
echo.
cd sns_rooster
flutter run -d chrome --web-port=3000
goto end

:admin
echo.
echo Starting Admin Portal on Web Browser...
echo Connecting to backend at: http://localhost:5000
echo Admin portal will be available at: http://localhost:3001
echo.
cd admin-portal
npm start
goto end

:both_physical
echo.
echo Starting Backend Server in background...
start "Backend Server" cmd /k "cd rooster-backend && node app.js"
timeout /t 3 /nobreak >nul
echo.
echo Starting Flutter App on Physical Android Device...
echo Connecting to backend at: http://192.168.1.80:5000
echo.
cd sns_rooster
flutter run --dart-define=USE_PHYSICAL_DEVICE_IP=true
goto end

:both_emulator
echo.
echo Starting Backend Server in background...
start "Backend Server" cmd /k "cd rooster-backend && node app.js"
timeout /t 3 /nobreak >nul
echo.
echo Starting Flutter App on Android Emulator...
echo Connecting to backend at: http://10.0.2.2:5000
echo.
cd sns_rooster
flutter run --dart-define=USE_PHYSICAL_DEVICE_IP=false
goto end

:both_web
echo.
echo Starting Backend Server in background...
start "Backend Server" cmd /k "cd rooster-backend && node app.js"
timeout /t 3 /nobreak >nul
echo.
echo Starting Flutter App on Web Browser...
echo Connecting to backend at: http://localhost:5000
echo Web app will be available at: http://localhost:3000
echo.
cd sns_rooster
flutter run -d chrome --web-port=3000
goto end

:both_admin
echo.
echo Starting Backend Server in background...
start "Backend Server" cmd /k "cd rooster-backend && node app.js"
timeout /t 3 /nobreak >nul
echo.
echo Starting Admin Portal on Web Browser...
echo Connecting to backend at: http://localhost:5000
echo Admin portal will be available at: http://localhost:3001
echo.
cd admin-portal
npm start
goto end

:invalid
echo Invalid choice! Please enter 1-10.
pause
goto end

:exit
echo Goodbye!
goto end

:end
pause 