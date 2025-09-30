@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

echo 테스트 1: 환경 변수 설정
set "VENV_PYTHON=%CD%\venv\Scripts\python.exe"
echo VENV_PYTHON=!VENV_PYTHON!
echo.

echo 테스트 2: Docker 확인
docker info >nul 2>&1
set DOCKER_STATUS=!errorlevel!
echo Docker 상태: !DOCKER_STATUS!
if !DOCKER_STATUS! neq 0 (
    echo Docker가 실행되지 않음
) else (
    echo Docker 실행 중
)
echo.

echo 테스트 3: Minikube 확인
minikube status >nul 2>&1
set MINIKUBE_STATUS=!errorlevel!
echo Minikube 상태: !MINIKUBE_STATUS!
if !MINIKUBE_STATUS! neq 0 (
    echo Minikube가 실행되지 않음
) else (
    echo Minikube 실행 중
)
echo.

echo 테스트 4: Kubernetes 확인
kubectl cluster-info >nul 2>&1
set K8S_STATUS=!errorlevel!
echo Kubernetes 상태: !K8S_STATUS!
echo.

echo ============================================
echo 모든 테스트 완료! 스크립트가 정상 종료됩니다.
echo ============================================
timeout /t 5
endlocal
