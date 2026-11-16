@echo off
setlocal
cd /d "%~dp0"
title Dex Explorer
chcp 65001 >nul 2>nul
set PYTHONUTF8=1

where py >nul 2>nul
if %errorlevel%==0 (
    py -3 build.py
) else (
    python build.py
)

if errorlevel 1 (
    echo.
    echo Builder exited with an error. Press any key to close.
    pause >nul
)
