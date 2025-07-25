@echo off
echo Building SNS Rooster Web App for Production...

flutter build web --release --dart-define=API_URL=https://sns-rooster.onrender.com/api --dart-define=FIREBASE_API_KEY=AIzaSyBWg9ySUE_XSpPF4T5Og1FLoazIZR8Orqg --dart-define=FIREBASE_PROJECT_ID=sns-rooster-8cca5 --dart-define=FIREBASE_MESSAGING_SENDER_ID=901502276055 --dart-define=FIREBASE_APP_ID=1:901502276055:web:f4f94088120f52dc8f7b92 --dart-define=GOOGLE_MAPS_API_KEY=AIzaSyCjFtMPrWvzlLcOZHhHAvNpVMwGVAFtcAo --dart-define=ENVIRONMENT=production --dart-define=APP_NAME=SNS-HR --dart-define=APP_VERSION=1.0.0

if %ERRORLEVEL% EQU 0 (
    echo Build completed successfully!
    echo Ready to deploy to Firebase!
) else (
    echo Build failed!
)

pause 