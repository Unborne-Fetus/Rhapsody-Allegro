@echo off
setlocal
cd /d "%~dp0"
echo RHAPSODY: ALLEGRO - REMOVE OLD MERGED BRANCHES
echo.
echo All five old branches came from pull requests already merged into main.
echo This checks their exact commit hashes before offering deletion.
echo It never deletes main or a branch that has new commits.
echo.
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0tools\cleanup_branches.ps1"
if errorlevel 1 echo Cleanup needs attention; see the message above.
echo.
pause
