@echo off
REM Blade & Sorcery Mod Doctor - Launcher
REM Open this file in Notepad to verify: it only runs the ModDoctor.ps1 script.
REM No hidden code, no internet access, no system changes.
title Blade & Sorcery Mod Doctor
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ModDoctor.ps1"
pause
