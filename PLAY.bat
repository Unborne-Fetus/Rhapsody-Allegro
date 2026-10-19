@echo off
setlocal
cd /d "%~dp0"
echo RHAPSODY: ALLEGRO - PLAY
echo The first launch downloads official portable Godot 4.5.1 if needed.
echo No administrator installation or GitHub Actions is required.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\portable_godot.ps1" -Mode play
if errorlevel 1 (
  echo.
  echo Unable to launch. See the error above, then try again.
  pause
  exit /b 1
)
exit /b 0
