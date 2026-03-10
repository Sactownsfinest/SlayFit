@echo off
echo Building SlayFit APK...
cd /d "%~dp0mobile"
call "C:\Users\Dan Maeon\flutter\bin\flutter.bat" build apk --debug --target-platform android-arm64
if %errorlevel% neq 0 (
    echo Build FAILED.
    pause
    exit /b 1
)
copy /Y "build\app\outputs\flutter-apk\app-debug.apk" "D:\slayfit.apk"
echo.
echo Done! APK saved to D:\slayfit.apk
pause
