@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

REM 디버그 로그 파일 생성
set "DEBUG_LOG=%CD%\debug.log"
echo ========== 실행 시작: %date% %time% ========== > "%DEBUG_LOG%"
echo 디버그 로그: %DEBUG_LOG%
echo.

cls
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║          🚀 Dev Calendar - 디버그 모드                       ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

REM ============================================================
REM 1. Python 가상환경 확인 및 생성
REM ============================================================
echo [단계 1/11] Python 가상환경 확인 중...
echo [단계 1/11] Python 가상환경 확인 중... >> "%DEBUG_LOG%"

if not exist "venv\" (
    echo    → 가상환경이 없습니다. 새로 생성합니다...
    echo    → 가상환경 생성 시작 >> "%DEBUG_LOG%"
    python -m venv venv
    set ERR=!errorlevel!
    echo    → python -m venv 결과: !ERR! >> "%DEBUG_LOG%"
    if !ERR! neq 0 (
        echo ❌ 가상환경 생성 실패!
        echo ERROR: 가상환경 생성 실패 !ERR! >> "%DEBUG_LOG%"
        pause
        exit /b 1
    )
    echo    ✅ 가상환경 생성 완료!
) else (
    echo    ✅ 가상환경이 이미 존재합니다.
    echo    ✅ 가상환경 존재함 >> "%DEBUG_LOG%"
)
echo [단계 1 완료] >> "%DEBUG_LOG%"
echo.

REM ============================================================
REM 2. 가상환경 활성화 및 의존성 설치
REM ============================================================
echo [단계 2/11] 의존성 패키지 확인 중...
echo [단계 2/11] 의존성 패키지 확인 중... >> "%DEBUG_LOG%"

set "VENV_PYTHON=%CD%\venv\Scripts\python.exe"
set "VENV_PIP=%CD%\venv\Scripts\pip.exe"

echo    → VENV_PYTHON: %VENV_PYTHON% >> "%DEBUG_LOG%"
echo    → VENV_PIP: %VENV_PIP% >> "%DEBUG_LOG%"

if not exist "%VENV_PYTHON%" (
    echo ❌ 가상환경 Python을 찾을 수 없습니다!
    echo ERROR: Python 찾을 수 없음 >> "%DEBUG_LOG%"
    pause
    exit /b 1
)

echo    → 가상환경 활성화 완료!
echo    → 가상환경 활성화 완료 >> "%DEBUG_LOG%"

if exist "requirements.txt" (
    echo    → 필요한 패키지를 설치합니다...
    echo    → pip 업그레이드 시작 >> "%DEBUG_LOG%"
    "%VENV_PIP%" install -q --upgrade pip 2>nul
    echo    → requirements 설치 시작 >> "%DEBUG_LOG%"
    "%VENV_PIP%" install -q -r requirements.txt
    set ERR=!errorlevel!
    echo    → pip install 결과: !ERR! >> "%DEBUG_LOG%"
    if !ERR! neq 0 (
        echo    ⚠️  일부 패키지 설치에 실패했을 수 있습니다.
    ) else (
        echo    ✅ 패키지 설치 완료!
    )
)
echo [단계 2 완료] >> "%DEBUG_LOG%"
echo.

REM ============================================================
REM 3. Docker Desktop 확인
REM ============================================================
echo [단계 3/11] Docker Desktop 상태 확인 중...
echo [단계 3/11] Docker Desktop 확인 >> "%DEBUG_LOG%"

docker info >nul 2>&1
set DOCKER_STATUS=!errorlevel!
echo    → Docker 상태: !DOCKER_STATUS! >> "%DEBUG_LOG%"

if !DOCKER_STATUS! neq 0 (
    echo ❌ Docker Desktop이 실행되지 않았습니다!
    echo ERROR: Docker 실행 안됨 >> "%DEBUG_LOG%"
    echo    → Docker Desktop을 시작한 후 다시 실행하세요.
    pause
    exit /b 1
)
echo    ✅ Docker Desktop 실행 중!
echo [단계 3 완료] >> "%DEBUG_LOG%"
echo.

REM ============================================================
REM 4. Minikube 상태 확인 및 시작
REM ============================================================
echo [단계 4/11] Minikube 상태 확인 중...
echo [단계 4/11] Minikube 확인 시작 >> "%DEBUG_LOG%"

echo    → minikube status 실행... >> "%DEBUG_LOG%"
minikube status >nul 2>&1
set MINIKUBE_STATUS=!errorlevel!
echo    → minikube status 결과: !MINIKUBE_STATUS! >> "%DEBUG_LOG%"

if !MINIKUBE_STATUS! neq 0 (
    echo    → Minikube가 실행되지 않았습니다. 시작합니다...
    echo    → Minikube 시작 명령 실행 >> "%DEBUG_LOG%"
    echo    ⏳ 시간이 걸릴 수 있습니다 (1~3분)...
    minikube start --driver=docker
    set ERR=!errorlevel!
    echo    → minikube start 결과: !ERR! >> "%DEBUG_LOG%"
    if !ERR! neq 0 (
        echo ❌ Minikube 시작 실패!
        echo ERROR: Minikube 시작 실패 !ERR! >> "%DEBUG_LOG%"
        pause
        exit /b 1
    )
    echo    ✅ Minikube 시작 완료!
) else (
    echo    ✅ Minikube가 이미 실행 중입니다.
)
echo [단계 4 완료] >> "%DEBUG_LOG%"
echo.

REM ============================================================
REM 5. Kubernetes 클러스터 확인
REM ============================================================
echo [단계 5/11] Kubernetes 클러스터 연결 확인 중...
echo [단계 5/11] Kubernetes 확인 >> "%DEBUG_LOG%"

kubectl cluster-info >nul 2>&1
set K8S_STATUS=!errorlevel!
echo    → kubectl 결과: !K8S_STATUS! >> "%DEBUG_LOG%"

if !K8S_STATUS! neq 0 (
    echo ❌ Kubernetes 클러스터에 연결할 수 없습니다.
    echo ERROR: K8s 연결 실패 >> "%DEBUG_LOG%"
    pause
    exit /b 1
)
echo    ✅ Kubernetes 연결 성공!
echo [단계 5 완료] >> "%DEBUG_LOG%"
echo.

echo [단계 6/11] ArgoCD 설치 확인 (생략)
echo [단계 6/11] ArgoCD 확인 생략 >> "%DEBUG_LOG%"
echo [단계 7/11] Jenkins 설치 확인 (생략)
echo [단계 7/11] Jenkins 확인 생략 >> "%DEBUG_LOG%"
echo [단계 8/11] Dev Calendar 배포 확인 (생략)
echo [단계 8/11] 배포 확인 생략 >> "%DEBUG_LOG%"
echo.

echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                    ✅ 디버그 테스트 완료!                    ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo 로그 파일: %DEBUG_LOG%
echo 이 파일을 확인하면 어디서 종료되었는지 알 수 있습니다.
echo.
echo [완료] 스크립트 종료 >> "%DEBUG_LOG%"
echo ========== 실행 종료: %date% %time% ========== >> "%DEBUG_LOG%"
echo.
echo 종료하려면 아무 키나 누르세요...
pause
endlocal
