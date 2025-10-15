@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%" >nul

rem Stop tiến trình cũ
if exist reco.pid (
  for /f "usebackq delims=" %%p in ("reco.pid") do set "PID=%%p"
  if not "%PID%"=="" taskkill /PID %PID% /F /T >nul 2>&1
  del /f /q reco.pid >nul 2>&1
)

rem Start uvicorn với --reload và ghi PID
powershell -NoProfile -Command ^
  "$p = Start-Process -NoNewWindow '%SCRIPT_DIR%.venv\Scripts\uvicorn.exe' -ArgumentList 'app:app --host 0.0.0.0 --port 8000 --reload' -WorkingDirectory '%SCRIPT_DIR%' -PassThru; ^
   $p.Id | Out-File -FilePath 'reco.pid' -Encoding ascii"

popd >nul
exit /b 0
