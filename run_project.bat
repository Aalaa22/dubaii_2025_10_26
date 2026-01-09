@echo off
setlocal enabledelayedexpansion
title Flutter Dubai Project Rebuilder & Runner
echo =========================================
echo   FLUTTER REBUILD SCRIPT - DUBAI APP
echo =========================================

:: 1. Cleaning the project
echo [1/3] Cleaning project...
call flutter clean
if %ERRORLEVEL% neq 0 goto :error

:: 2. Getting dependencies
echo [2/3] Fetching dependencies...
call flutter pub get
if %ERRORLEVEL% neq 0 goto :error

:: 3. Generating Localization files
echo [3/3] Generating Localization files...
call flutter gen-l10n
if %ERRORLEVEL% neq 0 goto :error

echo.
echo =========================================
echo        REBUILD COMPLETED SUCCESSFULLY!
echo =========================================
echo.

:menu
echo Choose what to do next:
echo [1] Run directly (flutter run)
echo [2] Choose device and run (flutter devices + run -d)
echo [3] Cancel and Exit
echo.

set /p choice="Enter your choice (1, 2, or 3): "

if "%choice%"=="1" (
    echo Launching App...
    call flutter run
    goto :end
)

if "%choice%"=="2" (
    echo.
    echo Searching for available devices...
    call flutter devices
    echo.
    set /p device_id="Copy and Paste the Device ID: "
    echo Running on device !device_id!...
    call flutter run -d !device_id!
    goto :end
)

if "%choice%"=="3" (
    echo Exiting...
    goto :end
)

:: If input is invalid
echo Invalid choice, please try again.
goto :menu

:error
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo        ERROR OCCURRED! STEP FAILED.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
pause
exit /b %ERRORLEVEL%

:end
echo.
echo Script finished.
pause