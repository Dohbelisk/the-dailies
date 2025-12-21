@echo off
REM The Dailies - Start All Services (Windows)

echo.
echo ========================================================
echo.
echo            THE DAILIES - STARTUP
echo.
echo ========================================================
echo.

REM Check Node.js
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed
    pause
    exit /b 1
)
echo [OK] Node.js found

REM Check npm
where npm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: npm is not installed
    pause
    exit /b 1
)
echo [OK] npm found

REM Check Flutter (optional)
where flutter >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Flutter found
) else (
    echo [WARN] Flutter not found (optional)
)

echo.
echo Installing dependencies if needed...
echo.

REM Install backend dependencies
if not exist "backend\node_modules" (
    echo Installing backend dependencies...
    cd backend
    call npm install
    cd ..
)

REM Install admin portal dependencies
if not exist "admin-portal\node_modules" (
    echo Installing admin portal dependencies...
    cd admin-portal
    call npm install
    cd ..
)

REM Copy .env if needed
if not exist "backend\.env" (
    echo Creating backend\.env from .env.example
    copy backend\.env.example backend\.env
)

echo.
echo ========================================================
echo            STARTING SERVICES
echo ========================================================
echo.

REM Start backend in new window
echo Starting Backend API...
start "The Dailies - Backend" cmd /k "cd backend && npm run start:dev"

REM Wait a moment
timeout /t 3 /nobreak >nul

REM Start admin portal in new window
echo Starting Admin Portal...
start "The Dailies - Admin Portal" cmd /k "cd admin-portal && npm run dev"

echo.
echo ========================================================
echo              SERVICES STARTED
echo ========================================================
echo.
echo Backend API:      http://localhost:3000
echo Swagger Docs:     http://localhost:3000/api/docs
echo Admin Portal:     http://localhost:5173
echo.
echo Default Login:    admin@dohbelisk.com / 5nifrenypro
echo.
echo To start Flutter app:
echo   cd flutter_app
echo   flutter run
echo.
echo Press any key to close this window (services will keep running)
pause >nul
