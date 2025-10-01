@echo off
REM ============================================================
REM Dev Calendar 자동 시작 스크립트
REM ============================================================
REM
REM 이 스크립트는 PowerShell 버전을 호출합니다.
REM Windows 배치 파일의 한계(minikube/kubectl 실행 시 종료)를
REM PowerShell로 우회합니다.
REM
REM ============================================================

REM UTF-8 코드페이지 설정 (한글 깨짐 방지)
chcp 65001 >nul 2>&1
cls

echo ===============================================================
echo          Dev Calendar - 자동 시작
echo ===============================================================
echo.
echo PowerShell 스크립트를 실행합니다...
echo.

REM PowerShell 실행 시 UTF-8 인코딩 명시
powershell -NoProfile -ExecutionPolicy Bypass -Command "$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; . '%~dp0start.ps1'"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] 오류가 발생했습니다!
    pause
    exit /b 1
)

exit /b 0
