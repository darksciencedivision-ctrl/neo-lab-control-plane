@echo off
setlocal
cd /d C:\ai_control\NEO_Stack
powershell -NoProfile -ExecutionPolicy Bypass -File ".\neo_loop.ps1"
endlocal
