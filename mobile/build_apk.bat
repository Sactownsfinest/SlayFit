@echo off
echo Building SlayFit APK...
call "C:\Users\Dan Maeon\flutter\bin\flutter.bat" build apk --debug
if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    exit /b 1
)
set SRC=build\app\outputs\flutter-apk\app-debug.apk
set DEST=build\app\outputs\flutter-apk\slayfit.apk
if exist "%DEST%" del "%DEST%"
rename "%SRC%" slayfit.apk
echo.
echo Done! APK: build\app\outputs\flutter-apk\slayfit.apk
