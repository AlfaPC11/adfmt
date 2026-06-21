@echo off
rem SPDX-License-Identifier: BSL-1.0

setlocal

set "BUILD_TYPE=%~1"
if not defined BUILD_TYPE set "BUILD_TYPE=release"

if /I not "%BUILD_TYPE%"=="debug" if /I not "%BUILD_TYPE%"=="release" (
  echo Usage: build.cmd [debug^|release]
  exit /b 2
)

set "COMPILER=%DC%"
if not defined COMPILER set "COMPILER=ldc2"

where dub >nul 2>&1
if errorlevel 1 (
  echo Error: DUB was not found in PATH.
  exit /b 1
)

dub build --build=%BUILD_TYPE% --compiler=%COMPILER%
exit /b %errorlevel%
