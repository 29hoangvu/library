@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%" >nul

if exist reco.pid (
  for /f "usebackq delims=" %%p in ("reco.pid") do set "PID=%%p"
  if not "%PID%"=="" taskkill /PID %PID% /F /T >nul 2>&1
  del /f /q reco.pid >nul 2>&1
)

popd >nul
exit /b 0
