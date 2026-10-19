@echo off
setlocal
cd /d "%~dp0"
echo RHAPSODY: ALLEGRO - WINDOWS + WEB BUILD
echo No administrator installation or GitHub Actions is required.
echo The first build downloads the official Godot 4.5.1 editor and export templates.
echo.
if /I "%~1"=="FAST" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\portable_godot.ps1" -Mode build -SkipTests
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\portable_godot.ps1" -Mode build
)
if errorlevel 1 (
  echo.
  echo Build failed. Check the error above.
  pause
  exit /b 1
)
echo.
echo Exported builds are in the build folder.
echo The Windows game is build\windows\Rhapsody-Allegro.exe
echo.
pause
exit /b 0
