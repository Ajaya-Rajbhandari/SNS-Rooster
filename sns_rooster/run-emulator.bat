@echo off
echo Starting SNS Rooster Flutter App on Android Emulator...
echo Connecting to backend at: http://10.0.2.2:5000
echo.
flutter run --dart-define=USE_PHYSICAL_DEVICE_IP=false
pause 