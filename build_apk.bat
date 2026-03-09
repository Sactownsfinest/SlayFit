@echo off
echo Building SlayFit APK...
cd /d "%~dp0mobile"
call "C:\Users\Dan Maeon\flutter\bin\flutter.bat" build apk --debug
if %errorlevel% neq 0 (
    echo Build FAILED.
    pause
    exit /b 1
)
del /f /q "build\app\outputs\flutter-apk\slayfit.apk" 2>nul
ren "build\app\outputs\flutter-apk\app-debug.apk" "slayfit.apk"
echo.
echo Done! APK ready at:
echo %~dp0mobile\build\app\outputs\flutter-apk\slayfit.apk
pause
