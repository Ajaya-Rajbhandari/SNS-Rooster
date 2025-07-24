#!/bin/bash

# SNS Rooster Web Build Script
# This script builds the Flutter web app with secure environment variables

echo "🔐 Building SNS Rooster Web App with secure configuration..."

# Check if environment variables are set
if [ -z "$API_URL" ]; then
    echo "❌ Error: API_URL environment variable is not set"
    exit 1
fi

if [ -z "$FIREBASE_API_KEY" ]; then
    echo "❌ Error: FIREBASE_API_KEY environment variable is not set"
    exit 1
fi

if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
    echo "❌ Error: GOOGLE_MAPS_API_KEY environment variable is not set"
    exit 1
fi

echo "✅ Environment variables validated"

# Build Flutter web app with environment variables
flutter build web \
  --dart-define=API_URL="$API_URL" \
  --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
  --dart-define=FIREBASE_APP_ID="$FIREBASE_APP_ID" \
  --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY" \
  --dart-define=ENVIRONMENT="$ENVIRONMENT" \
  --dart-define=APP_NAME="$APP_NAME" \
  --dart-define=APP_VERSION="$APP_VERSION" \
  --release

echo "✅ Web app built successfully!"
echo "📁 Output: build/web/" 