@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cls

echo ========================================
echo    최소 버전 - 한 단계씩 실행
echo ========================================
echo.

echo 1. 시작...
echo 1. 시작... (성공)
timeout /t 1 /nobreak >nul

echo 2. Python 확인...
if exist "venv\" (
    echo 2. Python 확인... (venv 존재)
) else (
    echo 2. Python 확인... (venv 없음)
)
timeout /t 1 /nobreak >nul

echo 3. Docker 확인...
docker info >nul 2>&1
set DOCKER_ERR=!errorlevel!
echo 3. Docker 확인... (결과: !DOCKER_ERR!)
timeout /t 1 /nobreak >nul

echo 4. Minikube 확인 직전...
timeout /t 1 /nobreak >nul
echo 4-1. minikube status 실행 중...
minikube status >nul 2>&1
set MINIKUBE_ERR=!errorlevel!
echo 4-2. minikube status 완료 (결과: !MINIKUBE_ERR!)
timeout /t 1 /nobreak >nul

echo 5. kubectl 확인...
kubectl version --client >nul 2>&1
set KUBECTL_ERR=!errorlevel!
echo 5. kubectl 확인... (결과: !KUBECTL_ERR!)
timeout /t 1 /nobreak >nul

echo.
echo ========================================
echo    모든 단계 완료!
echo ========================================
echo.
echo Docker: !DOCKER_ERR!
echo Minikube: !MINIKUBE_ERR!
echo kubectl: !KUBECTL_ERR!
echo.
echo 스크립트가 여기까지 도달했습니다!
echo 종료하려면 아무 키나 누르세요...
pause
endlocal
