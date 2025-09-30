@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cls
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║          🚀 Dev Calendar - 우회 버전                         ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

REM ============================================================
REM 1. Python 가상환경 확인 및 생성
REM ============================================================
echo [📦] Python 가상환경 확인 중...
if not exist "venv\" (
    echo    → 가상환경이 없습니다. 새로 생성합니다...
    python -m venv venv
    if !errorlevel! neq 0 (
        echo ❌ 가상환경 생성 실패!
        pause
        exit /b 1
    )
    echo    ✅ 가상환경 생성 완료!
) else (
    echo    ✅ 가상환경이 이미 존재합니다.
)
echo.

REM ============================================================
REM 2. 가상환경 활성화 및 의존성 설치
REM ============================================================
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
        echo    ⚠️  일부 패키지 설치에 실패했을 수 있습니다.
    ) else (
        echo    ✅ 패키지 설치 완료!
    )
)
echo.

REM ============================================================
REM 3. Docker Desktop 확인
REM ============================================================
echo [🐋] Docker Desktop 상태 확인 중...
docker info >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ Docker Desktop이 실행되지 않았습니다!
    pause
    exit /b 1
)
echo    ✅ Docker Desktop 실행 중!
echo.

REM ============================================================
REM 4. Minikube 상태 확인 (우회 방법)
REM ============================================================
echo [🔧] Minikube 상태 확인 중...

REM 방법 1: PowerShell을 통해 실행
powershell -Command "& {minikube status | Out-Null; exit $LASTEXITCODE}" >nul 2>&1
set MINIKUBE_STATUS=!errorlevel!

if !MINIKUBE_STATUS! neq 0 (
    echo    → Minikube가 실행되지 않았습니다. 시작합니다...
    echo    ⏳ 시간이 걸릴 수 있습니다 (1~3분)...
    powershell -Command "& {minikube start --driver=docker; exit $LASTEXITCODE}"
    if !errorlevel! neq 0 (
        echo ❌ Minikube 시작 실패!
        pause
        exit /b 1
    )
    echo    ✅ Minikube 시작 완료!
) else (
    echo    ✅ Minikube가 이미 실행 중입니다.
)
echo.

REM ============================================================
REM 5. Kubernetes 클러스터 확인
REM ============================================================
echo [📡] Kubernetes 클러스터 연결 확인 중...
powershell -Command "& {kubectl cluster-info | Out-Null; exit $LASTEXITCODE}" >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ Kubernetes 클러스터에 연결할 수 없습니다.
    pause
    exit /b 1
)
echo    ✅ Kubernetes 연결 성공!
echo.

REM ============================================================
REM 6. ArgoCD 설치 확인
REM ============================================================
echo [🔍] ArgoCD 설치 확인 중...
powershell -Command "& {kubectl get namespace argocd | Out-Null; exit $LASTEXITCODE}" >nul 2>&1
if !errorlevel! neq 0 (
    echo    → ArgoCD가 설치되지 않았습니다. 설치합니다...
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo    ⏳ ArgoCD Pod가 준비될 때까지 대기 중...
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
    if !errorlevel! neq 0 (
        echo    ⚠️  ArgoCD 설치 시간이 초과되었습니다. 계속 진행합니다...
    ) else (
        echo    ✅ ArgoCD 설치 완료!
    )
) else (
    echo    ✅ ArgoCD가 이미 설치되어 있습니다.
)
echo.

REM ============================================================
REM 7. Jenkins 설치 확인
REM ============================================================
echo [🔍] Jenkins 설치 확인 중...
powershell -Command "& {kubectl get namespace jenkins | Out-Null; exit $LASTEXITCODE}" >nul 2>&1
if !errorlevel! neq 0 (
    echo    → Jenkins Namespace가 없습니다.
) else (
    echo    ✅ Jenkins Namespace가 존재합니다.
)
echo.

REM ============================================================
REM 8. Dev Calendar 배포 확인
REM ============================================================
echo [🚀] Dev Calendar 배포 확인 중...
powershell -Command "& {kubectl get namespace dev | Out-Null; exit $LASTEXITCODE}" >nul 2>&1
if !errorlevel! neq 0 (
    echo    → Dev 환경이 없습니다. 배포합니다...
    if exist "deploy\k8s\overlays\dev" (
        kubectl apply -k deploy/k8s/overlays/dev
        echo    ⏳ Pod가 준비될 때까지 대기 중...
        timeout /t 10 /nobreak >nul
        echo    ✅ 배포 완료!
    )
) else (
    echo    ✅ Dev 환경이 이미 존재합니다.
    kubectl get pods -n dev 2>nul
)
echo.

REM ============================================================
REM 9. 포트포워딩 시작
REM ============================================================
echo [🔌] 포트포워딩 시작 중...
echo    → Dev Calendar (8081)
start /B kubectl port-forward -n dev svc/dev-dev-calendar 8081:80 2>nul

echo    → ArgoCD (8080)
start /B kubectl port-forward -n argocd svc/argocd-server 8080:443 2>nul

powershell -Command "& {kubectl get svc -n jenkins jenkins | Out-Null; exit $LASTEXITCODE}" >nul 2>&1
if !errorlevel! equ 0 (
    echo    → Jenkins (8090)
    start /B kubectl port-forward -n jenkins svc/jenkins 8090:8080 2>nul
)

echo.
echo [⏳] 서비스 준비 중... (8초)
timeout /t 8 /nobreak >nul

REM ============================================================
REM 10. 웹 브라우저 자동 실행
REM ============================================================
echo.
echo [🌐] 웹 브라우저 실행 중...

echo    → ArgoCD 관리자 비밀번호 조회 중...
for /f "tokens=*" %%i in ('kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath^="{.data.password}" 2^>nul ^| powershell -Command "$input | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }"') do set ARGOCD_PASSWORD=%%i

echo    → Dev Calendar 열기...
start http://localhost:8081/projects/
timeout /t 1 /nobreak >nul

echo    → ArgoCD 웹 UI 열기...
start https://localhost:8080
timeout /t 1 /nobreak >nul

powershell -Command "& {kubectl get svc -n jenkins jenkins | Out-Null; exit $LASTEXITCODE}" >nul 2>&1
if !errorlevel! equ 0 (
    echo    → Jenkins 웹 UI 열기...
    start http://localhost:8090
)

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                    ✅ 모든 서비스 실행 완료!                 ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo 📋 접속 정보:
echo   🎯 Dev Calendar: http://localhost:8081/projects/
echo   🔐 ArgoCD: https://localhost:8080
if defined ARGOCD_PASSWORD (
    echo      - ID: admin
    echo      - PW: !ARGOCD_PASSWORD!
)
echo.
echo 🛑 종료하려면 아무 키나 누르세요
pause >nul

echo.
echo [🛑] 서비스 종료 중...
taskkill /F /IM kubectl.exe >nul 2>&1
echo    ✅ 모든 서비스가 종료되었습니다.
timeout /t 3 /nobreak >nul
endlocal
