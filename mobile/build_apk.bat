@echo off
echo Building SlayFit APK...
call "C:\Users\Dan Maeon\flutter\bin\flutter.bat" build apk --release --target-platform android-arm64
if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    exit /b 1
)
set SRC=build\app\outputs\flutter-apk\app-release.apk
set DEST=build\app\outputs\flutter-apk\slayfit.apk
if exist "%DEST%" del "%DEST%"
rename "%SRC%" slayfit.apk
if exist "slayfit.apk" del "slayfit.apk"
copy "build\app\outputs\flutter-apk\slayfit.apk" "slayfit.apk" >nul
echo.
echo Done! APK: slayfit.apk
