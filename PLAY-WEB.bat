@echo off
setlocal
cd /d "%~dp0"
if exist "dist\index.html" (
  set "WEB_DIR=%~dp0dist"
) else if exist "build\web\index.html" (
  set "WEB_DIR=%~dp0build\web"
) else (
  echo No Web build found. Run build.bat first.
  pause
  exit /b 1
)
where py.exe >nul 2>nul
if not errorlevel 1 (
  start "" "http://127.0.0.1:8060/"
  py -3 -m http.server 8060 --bind 127.0.0.1 --directory "%WEB_DIR%"
  exit /b %errorlevel%
)
where python.exe >nul 2>nul
if not errorlevel 1 (
  start "" "http://127.0.0.1:8060/"
  python -m http.server 8060 --bind 127.0.0.1 --directory "%WEB_DIR%"
  exit /b %errorlevel%
)
echo Python 3 is needed to host a local Godot Web export.
echo You can still run the Windows EXE in build\windows\ without Python.
pause
exit /b 1
