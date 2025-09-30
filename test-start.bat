@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cls
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║          🧪 Dev Calendar - 단계별 테스트                     ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

echo ==================== 단계 1: Python 가상환경 ====================
echo [📦] Python 가상환경 확인 중...
if not exist "venv\" (
    echo    → 가상환경이 없습니다. 새로 생성합니다...
    python -m venv venv
    if !errorlevel! neq 0 (
        echo ❌ 실패: !errorlevel!
        pause
        exit /b 1
    )
    echo    ✅ 가상환경 생성 완료!
) else (
    echo    ✅ 가상환경이 이미 존재합니다.
)
echo 결과: 단계 1 통과
echo.
pause

echo ==================== 단계 2: 의존성 설치 ====================
echo [📚] 의존성 패키지 확인 중...
set "VENV_PYTHON=%CD%\venv\Scripts\python.exe"
set "VENV_PIP=%CD%\venv\Scripts\pip.exe"

if not exist "%VENV_PYTHON%" (
    echo ❌ 가상환경 Python을 찾을 수 없습니다!
    pause
    exit /b 1
)

echo    → 가상환경 활성화 완료!
if exist "requirements.txt" (
    echo    → 필요한 패키지를 설치합니다...
    "%VENV_PIP%" install -q --upgrade pip 2>nul
    "%VENV_PIP%" install -q -r requirements.txt
    if !errorlevel! neq 0 (
        echo    ⚠️  일부 패키지 설치에 실패: !errorlevel!
    ) else (
        echo    ✅ 패키지 설치 완료!
    )
)
echo 결과: 단계 2 통과
echo.
pause

echo ==================== 단계 3: Docker 확인 ====================
echo [🐋] Docker Desktop 상태 확인 중...
docker info >nul 2>&1
set DOCKER_STATUS=!errorlevel!
if !DOCKER_STATUS! neq 0 (
    echo ❌ Docker Desktop이 실행되지 않았습니다: !DOCKER_STATUS!
    echo    → Docker Desktop을 시작한 후 다시 실행하세요.
    pause
    exit /b 1
)
echo    ✅ Docker Desktop 실행 중!
echo 결과: 단계 3 통과
echo.
pause

echo ==================== 단계 4: Minikube 확인 ====================
echo [🔧] Minikube 상태 확인 중...
minikube status >nul 2>&1
set MINIKUBE_STATUS=!errorlevel!
echo    → Minikube status 결과: !MINIKUBE_STATUS!

if !MINIKUBE_STATUS! neq 0 (
    echo    → Minikube가 실행되지 않았습니다.
    echo    → 테스트 모드에서는 시작하지 않습니다.
) else (
    echo    ✅ Minikube가 이미 실행 중입니다.
)
echo 결과: 단계 4 통과 (상태: !MINIKUBE_STATUS!)
echo.
pause

echo ==================== 단계 5: Kubernetes 확인 ====================
echo [📡] Kubernetes 클러스터 연결 확인 중...
kubectl cluster-info >nul 2>&1
set K8S_STATUS=!errorlevel!
if !K8S_STATUS! neq 0 (
    echo    ⚠️  Kubernetes 클러스터에 연결할 수 없습니다: !K8S_STATUS!
    echo    → Minikube가 실행되지 않은 것 같습니다.
) else (
    echo    ✅ Kubernetes 연결 성공!
)
echo 결과: 단계 5 통과 (상태: !K8S_STATUS!)
echo.
pause

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                    ✅ 모든 단계 테스트 완료!                 ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo 요약:
echo - Python 가상환경: ✅
echo - 의존성 설치: ✅
echo - Docker Desktop: ✅
echo - Minikube: !MINIKUBE_STATUS!
echo - Kubernetes: !K8S_STATUS!
echo.
echo 스크립트가 중간에 종료되지 않고 여기까지 실행되었습니다!
echo 종료하려면 아무 키나 누르세요...
pause
endlocal
