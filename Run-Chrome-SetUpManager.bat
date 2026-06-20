@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"""%~dp0Chrome-TurnOff-Telemmetry-UI-permissions.ps1\"""' -Verb RunAs"