@echo off
chcp 65001 >nul
cls
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║          🚀 Dev Calendar - 자동 시작 스크립트                ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

REM ============================================================
REM 1. Python 가상환경 확인 및 생성
REM ============================================================
echo [📦] Python 가상환경 확인 중...
if not exist "venv\" (
    echo    → 가상환경이 없습니다. 새로 생성합니다...
    python -m venv venv
    if errorlevel 1 (
        echo ❌ 가상환경 생성 실패! Python이 설치되어 있는지 확인하세요.
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

REM 가상환경 Python 경로 설정
set VENV_PYTHON=%CD%\venv\Scripts\python.exe
set VENV_PIP=%CD%\venv\Scripts\pip.exe

if not exist "%VENV_PYTHON%" (
    echo ❌ 가상환경 Python을 찾을 수 없습니다!
    pause
    exit /b 1
)

echo    → 가상환경 활성화 완료!

REM requirements.txt가 있으면 pip install 실행
if exist "requirements.txt" (
    echo    → 필요한 패키지를 설치합니다...
    "%VENV_PIP%" install -q --upgrade pip 2>nul
    "%VENV_PIP%" install -q -r requirements.txt
    if errorlevel 1 (
        echo    ⚠️  일부 패키지 설치에 실패했을 수 있습니다.
    ) else (
        echo    ✅ 패키지 설치 완료!
    )
) else (
    echo    ⚠️  requirements.txt 파일을 찾을 수 없습니다.
)
echo.

REM ============================================================
REM 3. Minikube 상태 확인 및 시작
REM ============================================================
echo [🔧] Minikube 상태 확인 중...
minikube status >nul 2>&1
if errorlevel 1 (
    echo    → Minikube가 실행되지 않았습니다. 시작합니다...
    echo    ⏳ 시간이 걸릴 수 있습니다 (1~3분)...
    minikube start --driver=docker
    if errorlevel 1 (
        echo ❌ Minikube 시작 실패! Docker Desktop이 실행 중인지 확인하세요.
        pause
        exit /b 1
    )
    echo    ✅ Minikube 시작 완료!
) else (
    echo    ✅ Minikube가 이미 실행 중입니다.
)
echo.

REM ============================================================
REM 4. Kubernetes 클러스터 확인
REM ============================================================
echo [📡] Kubernetes 클러스터 연결 확인 중...
kubectl cluster-info >nul 2>&1
if errorlevel 1 (
    echo ❌ Kubernetes 클러스터에 연결할 수 없습니다.
    pause
    exit /b 1
)
echo    ✅ Kubernetes 연결 성공!
echo.

REM ============================================================
REM 5. ArgoCD 설치 확인
REM ============================================================
echo [🔍] ArgoCD 설치 확인 중...
kubectl get namespace argocd >nul 2>&1
if errorlevel 1 (
    echo    → ArgoCD가 설치되지 않았습니다. 설치합니다...
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo    ⏳ ArgoCD Pod가 준비될 때까지 대기 중...
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
    echo    ✅ ArgoCD 설치 완료!
) else (
    echo    ✅ ArgoCD가 이미 설치되어 있습니다.
)
echo.

REM ============================================================
REM 6. Jenkins 설치 확인
REM ============================================================
echo [🔍] Jenkins 설치 확인 중...
kubectl get namespace jenkins >nul 2>&1
if errorlevel 1 (
    echo    → Jenkins가 설치되지 않았습니다. 설치합니다...
    kubectl create namespace jenkins
    echo    ⚠️  Jenkins 설치는 수동으로 진행해야 합니다.
    echo    ℹ️  Jenkins를 사용하지 않으려면 무시하세요.
) else (
    echo    ✅ Jenkins Namespace가 존재합니다.
)
echo.

REM ============================================================
REM 7. Dev Calendar 배포 확인
REM ============================================================
echo [🚀] Dev Calendar 배포 확인 중...
kubectl get namespace dev >nul 2>&1
if errorlevel 1 (
    echo    → Dev 환경이 없습니다. 배포합니다...
    kubectl apply -k deploy/k8s/overlays/dev
    echo    ⏳ Pod가 준비될 때까지 대기 중...
    timeout /t 10 /nobreak >nul
    echo    ✅ 배포 완료!
) else (
    echo    ✅ Dev 환경이 이미 존재합니다.
    kubectl get pods -n dev
)
echo.

REM ============================================================
REM 8. 포트포워딩 시작
REM ============================================================
echo [🔌] 포트포워딩 시작 중...
echo    → Dev Calendar (8081)
start /B kubectl port-forward -n dev svc/dev-dev-calendar 8081:80 2>nul

echo    → ArgoCD (8080)
start /B kubectl port-forward -n argocd svc/argocd-server 8080:443 2>nul

REM Jenkins가 있으면 포트포워딩
kubectl get svc -n jenkins jenkins >nul 2>&1
if not errorlevel 1 (
    echo    → Jenkins (8090)
    start /B kubectl port-forward -n jenkins svc/jenkins 8090:8080 2>nul
)

echo.
echo [⏳] 서비스 준비 중... (8초)
timeout /t 8 /nobreak >nul

REM ============================================================
REM 9. 웹 브라우저 자동 실행
REM ============================================================
echo.
echo [🌐] 웹 브라우저 실행 중...

REM ArgoCD 비밀번호 가져오기
echo    → ArgoCD 관리자 비밀번호 조회 중...
for /f "tokens=*" %%i in ('kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath^="{.data.password}" 2^>nul ^| powershell -Command "$input | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }"') do set ARGOCD_PASSWORD=%%i

REM Dev Calendar 열기
echo    → Dev Calendar 열기...
start http://localhost:8081/projects/
timeout /t 1 /nobreak >nul

REM ArgoCD 웹 UI 열기
echo    → ArgoCD 웹 UI 열기...
start https://localhost:8080
timeout /t 1 /nobreak >nul

REM Jenkins가 있으면 열기
kubectl get svc -n jenkins jenkins >nul 2>&1
if not errorlevel 1 (
    echo    → Jenkins 웹 UI 열기...
    start http://localhost:8090
)

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                    ✅ 모든 서비스 실행 완료!                 ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo 📋 접속 정보 (모든 브라우저가 자동으로 열렸습니다):
echo ┌───────────────────────────────────────────────────────────────┐
echo │ 🎯 Dev Calendar    http://localhost:8081/projects/            │
echo │                                                               │
echo │ 🔐 ArgoCD          https://localhost:8080                     │
if defined ARGOCD_PASSWORD (
    echo │   - ID: admin                                                 │
    echo │   - PW: %ARGOCD_PASSWORD%                                     │
    echo │   ※ Applications 메뉴에서 배포 상태를 확인하세요!            │
) else (
    echo │   - 비밀번호를 가져올 수 없습니다. ArgoCD 설치를 확인하세요.  │
)
kubectl get svc -n jenkins jenkins >nul 2>&1
if not errorlevel 1 (
    echo │                                                               │
    echo │ 🛠️  Jenkins         http://localhost:8090                     │
)
echo └───────────────────────────────────────────────────────────────┘
echo.
echo 💡 사용 팁:
echo    - Dev Calendar, ArgoCD, Jenkins 웹 UI가 자동으로 열렸습니다!
echo    - ArgoCD는 HTTPS이므로 보안 경고 나오면 "고급 → 계속 진행" 클릭
echo    - ArgoCD에서 dev-dev-calendar와 prod-prod-calendar 앱 상태 확인 가능
echo    - 이 창을 닫으면 모든 포트포워딩이 종료됩니다
echo.
echo 🛑 종료하려면 아무 키나 누르세요
echo.
pause >nul

REM ============================================================
REM 10. 종료 처리
REM ============================================================
echo.
echo [🛑] 서비스 종료 중...

REM 포트포워딩 프로세스 종료
echo    → 포트포워딩 종료 중...
taskkill /F /IM kubectl.exe >nul 2>&1

REM 가상환경은 별도 프로세스로 실행되지 않으므로 종료 불필요
echo    → 환경 변수 정리 중...
set VENV_PYTHON=
set VENV_PIP=

REM 선택: Minikube 종료 (나중에 지속 서비스시 주석 처리하면 됨)
REM echo    → Minikube 종료 중...
REM minikube stop
REM echo    ✅ Minikube 종료 완료!

echo    ✅ 모든 서비스가 종료되었습니다.
echo.
echo 💡 참고:
echo    - Minikube는 계속 실행 중입니다 (빠른 재시작을 위해)
echo    - 완전히 종료하려면: minikube stop
echo    - 지속 서비스가 필요하면 스크립트를 수정하세요
echo.
timeout /t 3 /nobreak >nul
