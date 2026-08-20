@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\UpdateProgramCatalog.ps1" "%~dp0."
exit /b %ERRORLEVEL%
