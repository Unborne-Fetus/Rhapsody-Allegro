@echo off
setlocal
cd /d "%~dp0"
echo.
echo RHAPSODY: ALLEGRO - PUBLISH GITHUB PAGES (MAIN ONLY)
echo Builds a verified Web export and stages it for GitHub Pages.
echo This does NOT create another branch or change repository privacy.
echo.
if /I "%~1"=="STAGE" goto STAGE
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0tools\portable_godot.ps1" -Mode build
if errorlevel 1 (
 echo.
 echo The Godot build did not pass. No website files were published.
 echo See build\last-build-error.txt for details.
 pause
 exit /b 1
)
:STAGE
if /I "%~1"=="STAGE" (
 powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0tools\publish_pages.ps1" -StageOnly
) else (
 powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0tools\publish_pages.ps1"
)
if errorlevel 1 (
 echo.
 echo Page publishing failed. See the error above.
 pause
 exit /b 1
)
echo.
echo GitHub Pages setup: Repository Settings ^> Pages ^> main /docs.
echo The site will be accessible after GitHub Pages finishes publishing.
pause
exit /b 0
