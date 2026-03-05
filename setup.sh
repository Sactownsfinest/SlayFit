#!/bin/bash

# SlayFit Development Setup Script

echo "🚀 Setting up SlayFit development environment..."

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Install from https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter: $(flutter --version)"

# Setup mobile
echo ""
echo "📱 Setting up Flutter mobile app..."
cd mobile
flutter pub get
cd ..

# Setup backend
echo ""
echo "🔧 Setting up Python backend..."
cd backend

# Check Python
if ! command -v python &> /dev/null; then
    if ! command -v python3 &> /dev/null; then
        echo "❌ Python not found"
        exit 1
    fi
fi

PYTHON=$(command -v python3 || command -v python)
$PYTHON -m venv venv

if [ -d "venv/Scripts" ]; then
    # Windows
    source venv/Scripts/activate
else
    # Unix
    source venv/bin/activate
fi

pip install -e ".[dev]"

cd ..

echo ""
echo "✅ Setup complete!"
echo ""
echo "📱 To run mobile app:"
echo "   cd mobile && flutter run"
echo ""
echo "🔧 To run backend:"
echo "   cd backend && source venv/bin/activate && uvicorn main:app --reload"
echo ""
echo "📦 To build APK:"
echo "   cd mobile && flutter build apk --release"
