@echo off
cd /d "%~dp0"
REM Right-click this file and choose "Run as administrator"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Run-All.ps1" %*
pause
