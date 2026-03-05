@echo off
REM SlayFit Development Setup Script for Windows

echo.
echo 🚀 Setting up SlayFit development environment...
echo.

REM Check Flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter not found. Install from https://flutter.dev/docs/get-started/install
    exit /b 1
)

for /f "tokens=*" %%i in ('flutter --version') do set FLUTTER_VERSION=%%i
echo ✅ Flutter: %FLUTTER_VERSION%

REM Setup mobile
echo.
echo 📱 Setting up Flutter mobile app...
cd mobile
call flutter pub get
cd ..

REM Setup backend
echo.
echo 🔧 Setting up Python backend...
cd backend

python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python not found
    exit /b 1
)

python -m venv venv
call venv\Scripts\activate.bat

pip install -e ".[dev]"

cd ..

echo.
echo ✅ Setup complete!
echo.
echo 📱 To run mobile app:
echo    cd mobile
echo    flutter run
echo.
echo 🔧 To run backend:
echo    cd backend
echo    venv\Scripts\activate.bat
echo    uvicorn main:app --reload
echo.
echo 📦 To build APK:
echo    cd mobile
echo    flutter build apk --release
echo.
