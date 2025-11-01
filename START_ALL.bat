@echo off
echo ========================================
echo    Starting Bus Tracking System
echo ========================================
echo.

cd /d "%~dp0Buses_BACK_END-main"

echo [1/2] Starting Django Server...
start "Django Server" cmd /k "python manage.py runserver 0.0.0.0:8000"

timeout /t 5 /nobreak >nul

echo [2/2] Starting ngrok tunnel...
start "ngrok" ngrok http 8000

timeout /t 3 /nobreak >nul

echo.
echo ========================================
echo    ALL SERVICES STARTED!
echo ========================================
echo.
echo Django: http://localhost:8000
echo ngrok: Check the ngrok window for URL
echo.
echo Press any key to exit...
pause >nul
