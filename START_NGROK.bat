@echo off
echo ========================================
echo Starting ngrok tunnel on port 8000
echo ========================================
echo.
echo If Windows Defender blocks ngrok:
echo 1. Go to Windows Security
echo 2. Virus & threat protection
echo 3. Protection history
echo 4. Allow ngrok.exe
echo.
echo Or download from: https://ngrok.com/download
echo.
pause
"%USERPROFILE%\ngrok\ngrok.exe" http 8000
