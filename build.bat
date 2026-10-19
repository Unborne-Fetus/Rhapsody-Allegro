@echo off
setlocal
cd /d "%~dp0"
if not defined GODOT set "GODOT=godot"
where "%GODOT%" >nul 2>nul
if errorlevel 1 (
 echo Set GODOT to the path of your Godot 4.5.1 executable, or add Godot to PATH.
 pause
 exit /b 1
)
if not exist build\web mkdir build\web
if not exist build\windows mkdir build\windows
type nul > build\.gdignore
"%GODOT%" --headless --editor --import --quit
if errorlevel 1 exit /b 1
"%GODOT%" --headless --script res://tests/combat_test.gd
if errorlevel 1 exit /b 1
"%GODOT%" --headless --script res://tests/advanced_test.gd
if errorlevel 1 exit /b 1
"%GODOT%" --headless --script res://tests/input_test.gd
if errorlevel 1 exit /b 1
"%GODOT%" --headless --export-release Web
if errorlevel 1 exit /b 1
"%GODOT%" --headless --export-release Windows
if errorlevel 1 exit /b 1
echo Web and Windows builds are in build\. Host build\web over HTTP to test it.
pause
