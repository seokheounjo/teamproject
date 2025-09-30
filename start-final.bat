@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cls
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║          🚀 Dev Calendar - 최종 버전                         ║
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
REM 4. Kubernetes 클러스터 확인 (minikube 우회)
REM ============================================================
echo [📡] Kubernetes 클러스터 연결 확인 중...

REM kubectl로 직접 클러스터 확인 (minikube 명령어 사용 안 함)
kubectl cluster-info >nul 2>&1
if !errorlevel! neq 0 (
    echo    → Kubernetes 클러스터에 연결할 수 없습니다.
    echo    → Minikube를 시작합니다...
    echo    ⏳ 시간이 걸릴 수 있습니다 (1~3분)...

    REM 방법 1: 명령어를 파일로 저장 후 실행
    echo minikube start --driver=docker > %TEMP%\start-minikube.bat
    call %TEMP%\start-minikube.bat
    del %TEMP%\start-minikube.bat

    if !errorlevel! neq 0 (
        echo ❌ Minikube 시작 실패!
        pause
        exit /b 1
    )
    echo    ✅ Minikube 시작 완료!
) else (
    echo    ✅ Kubernetes 연결 성공! (Minikube 실행 중)
)
echo.

REM ============================================================
REM 5. ArgoCD 설치 확인
REM ============================================================
echo [🔍] ArgoCD 설치 확인 중...
kubectl get namespace argocd >nul 2>&1
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
REM 6. Jenkins 설치 확인
REM ============================================================
echo [🔍] Jenkins 설치 확인 중...
kubectl get namespace jenkins >nul 2>&1
if !errorlevel! neq 0 (
    echo    → Jenkins Namespace가 없습니다.
) else (
    echo    ✅ Jenkins Namespace가 존재합니다.
)
echo.

REM ============================================================
REM 7. Dev Calendar 배포 확인
REM ============================================================
echo [🚀] Dev Calendar 배포 확인 중...
kubectl get namespace dev >nul 2>&1
if !errorlevel! neq 0 (
    echo    → Dev 환경이 없습니다. 배포합니다...
    if exist "deploy\k8s\overlays\dev" (
        kubectl apply -k deploy/k8s/overlays/dev
        echo    ⏳ Pod가 준비될 때까지 대기 중...
        timeout /t 10 /nobreak >nul
        echo    ✅ 배포 완료!
    ) else (
        echo    ⚠️  배포 디렉토리를 찾을 수 없습니다.
    )
) else (
    echo    ✅ Dev 환경이 이미 존재합니다.
    kubectl get pods -n dev 2>nul
)
echo.

REM ============================================================
REM 8. ArgoCD 비밀번호 조회 및 자동 로그인 준비
REM ============================================================
echo [🔐] ArgoCD 자동 로그인 준비 중...
for /f "tokens=*" %%i in ('kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath^="{.data.password}" 2^>nul ^| powershell -Command "$input | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }"') do set ARGOCD_PASSWORD=%%i

if defined ARGOCD_PASSWORD (
    echo    ✅ ArgoCD 비밀번호 조회 성공
    echo    → ID: admin
    echo    → PW: !ARGOCD_PASSWORD!

    REM ArgoCD CLI 설치 확인 및 로그인
    where argocd >nul 2>&1
    if !errorlevel! equ 0 (
        echo    → ArgoCD CLI 발견, 자동 로그인 시도...
        REM 포트포워딩이 시작된 후 로그인할 예정
    ) else (
        echo    → ArgoCD CLI 없음 (웹 UI에서 수동 로그인)
    )
) else (
    echo    ⚠️  ArgoCD 비밀번호를 가져올 수 없습니다.
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

kubectl get svc -n jenkins jenkins >nul 2>&1
if !errorlevel! equ 0 (
    echo    → Jenkins (8090)
    start /B kubectl port-forward -n jenkins svc/jenkins 8090:8080 2>nul
)

echo.
echo [⏳] 서비스 준비 중... (10초)
timeout /t 10 /nobreak >nul

REM ============================================================
REM 10. ArgoCD 자동 로그인 (CLI 사용)
REM ============================================================
if defined ARGOCD_PASSWORD (
    where argocd >nul 2>&1
    if !errorlevel! equ 0 (
        echo [🔐] ArgoCD CLI 자동 로그인 시도...
        echo !ARGOCD_PASSWORD! | argocd login localhost:8080 --username admin --password-stdin --insecure >nul 2>&1
        if !errorlevel! equ 0 (
            echo    ✅ ArgoCD 자동 로그인 성공!
        ) else (
            echo    → CLI 로그인 실패 (웹 UI 사용)
        )
    )
)

REM ============================================================
REM 11. 웹 브라우저 자동 실행
REM ============================================================
echo.
echo [🌐] 웹 브라우저 실행 중...

echo    → Dev Calendar 열기...
start http://localhost:8081/projects/
timeout /t 1 /nobreak >nul

echo    → ArgoCD 웹 UI 열기...
REM ArgoCD 로그인 페이지에 자동 입력을 위한 HTML 파일 생성
if defined ARGOCD_PASSWORD (
    echo ^<html^>^<head^>^<meta charset="utf-8"^>^<title^>ArgoCD Auto Login^</title^>^</head^> > %TEMP%\argocd-login.html
    echo ^<body^>^<h2^>ArgoCD 자동 로그인 정보^</h2^> >> %TEMP%\argocd-login.html
    echo ^<p^>ID: ^<strong^>admin^</strong^>^</p^> >> %TEMP%\argocd-login.html
    echo ^<p^>Password: ^<strong^>!ARGOCD_PASSWORD!^</strong^>^</p^> >> %TEMP%\argocd-login.html
    echo ^<p^>^<a href="https://localhost:8080" target="_blank"^>ArgoCD 웹 UI 열기^</a^>^</p^> >> %TEMP%\argocd-login.html
    echo ^<script^>setTimeout(function(){ window.open('https://localhost:8080', '_blank'); }, 2000);^</script^> >> %TEMP%\argocd-login.html
    echo ^</body^>^</html^> >> %TEMP%\argocd-login.html
    start %TEMP%\argocd-login.html
) else (
    start https://localhost:8080
)
timeout /t 1 /nobreak >nul

kubectl get svc -n jenkins jenkins >nul 2>&1
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
echo ┌───────────────────────────────────────────────────────────────┐
echo │ 🎯 Dev Calendar    http://localhost:8081/projects/            │
echo │                                                               │
echo │ 🔐 ArgoCD          https://localhost:8080                     │
if defined ARGOCD_PASSWORD (
    echo │   - ID: admin                                                 │
    echo │   - PW: !ARGOCD_PASSWORD!                                     │
    echo │   ※ 로그인 정보가 별도 창에 표시되었습니다!                  │
) else (
    echo │   - 비밀번호를 가져올 수 없습니다. ArgoCD 설치를 확인하세요.  │
)
kubectl get svc -n jenkins jenkins >nul 2>&1
if !errorlevel! equ 0 (
    echo │                                                               │
    echo │ 🛠️  Jenkins         http://localhost:8090                     │
)
echo └───────────────────────────────────────────────────────────────┘
echo.
echo 💡 사용 팁:
echo    - ArgoCD 로그인 정보가 자동으로 표시됩니다!
echo    - 2초 후 ArgoCD 웹 UI가 자동으로 열립니다
echo    - ID/PW를 복사해서 로그인하세요
echo    - ArgoCD에서 dev-dev-calendar와 prod-prod-calendar 앱 확인 가능
echo.
echo 🛑 종료하려면 아무 키나 누르세요
echo.
pause >nul

REM ============================================================
REM 12. 종료 처리
REM ============================================================
echo.
echo [🛑] 서비스 종료 중...

REM 포트포워딩 프로세스 종료
echo    → 포트포워딩 종료 중...
taskkill /F /IM kubectl.exe >nul 2>&1

REM 임시 파일 정리
if exist "%TEMP%\argocd-login.html" del "%TEMP%\argocd-login.html"

echo    ✅ 모든 서비스가 종료되었습니다.
echo.
timeout /t 3 /nobreak >nul
endlocal
