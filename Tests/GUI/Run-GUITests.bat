@echo off
REM =============================================================================
REM GA-TemplateApp GUI Test Runner
REM =============================================================================
REM Run automated GUI tests using AutoIt
REM
REM Usage:
REM   Run-GUITests.bat [quick|full|verbose]
REM =============================================================================

setlocal EnableDelayedExpansion

echo ============================================
echo GA-TemplateApp GUI Test Runner
echo ============================================
echo.

REM Check for AutoIt installation
set "AUTOIT_PATH=C:\Program Files (x86)\AutoIt3\AutoIt3.exe"
if not exist "%AUTOIT_PATH%" (
    set "AUTOIT_PATH=C:\Program Files\AutoIt3\AutoIt3.exe"
)

if not exist "%AUTOIT_PATH%" (
    echo ERROR: AutoIt3 not found!
    echo Please install AutoIt from https://www.autoitscript.com/
    echo.
    pause
    exit /b 1
)

echo AutoIt found at: %AUTOIT_PATH%
echo.

REM Check for test script
set "SCRIPT_DIR=%~dp0"
set "TEST_SCRIPT=%SCRIPT_DIR%GA-TemplateApp-GUI-Test.au3"

if not exist "%TEST_SCRIPT%" (
    echo ERROR: Test script not found: %TEST_SCRIPT%
    pause
    exit /b 1
)

REM Parse arguments
set "TEST_ARGS="
if /i "%1"=="quick" set "TEST_ARGS=/quick"
if /i "%1"=="full" set "TEST_ARGS=/full"
if /i "%1"=="verbose" set "TEST_ARGS=/verbose"

REM Check for EXE
set "APP_EXE=%SCRIPT_DIR%..\..\GA-TemplateApp.exe"
if not exist "%APP_EXE%" (
    echo WARNING: GA-TemplateApp.exe not found!
    echo Expected location: %APP_EXE%
    echo.
    echo Please build the application first:
    echo   .\build\Build-GUI.ps1
    echo.
    set /p CONTINUE="Continue anyway? (y/n): "
    if /i not "!CONTINUE!"=="y" exit /b 1
)

echo Running tests...
echo.

REM Run tests
"%AUTOIT_PATH%" "%TEST_SCRIPT%" %TEST_ARGS%
set "EXIT_CODE=%ERRORLEVEL%"

echo.
echo ============================================
if %EXIT_CODE% EQU 0 (
    echo TEST RESULT: PASSED
) else (
    echo TEST RESULT: FAILED
)
echo ============================================
echo.

pause
exit /b %EXIT_CODE%
