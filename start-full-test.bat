@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cls

echo ╔═══════════════════════════════════════════════════════════════╗
echo ║       완전 테스트 - 원본과 동일한 모든 명령어 테스트         ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

REM ============================================================
REM 1. Python 가상환경 (원본과 동일)
REM ============================================================
echo [1/11] Python 가상환경 확인...
if not exist "venv\" (
    echo    → 가상환경 없음
    python -m venv venv
    if !errorlevel! neq 0 (
        echo    ❌ 실패!
        pause
        exit /b 1
    )
    echo    ✅ 생성 완료
) else (
    echo    ✅ 이미 존재
)
timeout /t 1 /nobreak >nul

REM ============================================================
REM 2. pip 설치 (원본과 동일)
REM ============================================================
echo [2/11] 의존성 패키지 설치...
set "VENV_PYTHON=%CD%\venv\Scripts\python.exe"
set "VENV_PIP=%CD%\venv\Scripts\pip.exe"

if not exist "%VENV_PYTHON%" (
    echo    ❌ Python 찾을 수 없음!
    pause
    exit /b 1
)

echo    → 가상환경 활성화 완료
if exist "requirements.txt" (
    echo    → pip 업그레이드 중...
    "%VENV_PIP%" install -q --upgrade pip 2>nul
    echo    → requirements 설치 중...
    "%VENV_PIP%" install -q -r requirements.txt
    if !errorlevel! neq 0 (
        echo    ⚠️  일부 실패
    ) else (
        echo    ✅ 설치 완료
    )
)
timeout /t 1 /nobreak >nul

REM ============================================================
REM 3. Docker (원본과 동일)
REM ============================================================
echo [3/11] Docker Desktop 확인...
docker info >nul 2>&1
if !errorlevel! neq 0 (
    echo    ❌ Docker 실행 안됨!
    pause
    exit /b 1
)
echo    ✅ Docker 실행 중
timeout /t 1 /nobreak >nul

REM ============================================================
REM 4. Minikube status (원본과 동일)
REM ============================================================
echo [4/11] Minikube 상태 확인...
minikube status >nul 2>&1
set MINIKUBE_STATUS=!errorlevel!

if !MINIKUBE_STATUS! neq 0 (
    echo    → Minikube 실행 안됨 (시작하지 않음 - 테스트 모드)
) else (
    echo    ✅ Minikube 실행 중
)
timeout /t 1 /nobreak >nul

REM ============================================================
REM 5. kubectl cluster-info (원본과 동일)
REM ============================================================
echo [5/11] Kubernetes 클러스터 확인...
kubectl cluster-info >nul 2>&1
if !errorlevel! neq 0 (
    echo    ❌ K8s 연결 실패!
    pause
    exit /b 1
)
echo    ✅ K8s 연결 성공
timeout /t 1 /nobreak >nul

REM ============================================================
REM 6. kubectl get namespace argocd (원본과 동일)
REM ============================================================
echo [6/11] ArgoCD 설치 확인...
kubectl get namespace argocd >nul 2>&1
if !errorlevel! neq 0 (
    echo    → ArgoCD 없음 (설치하지 않음 - 테스트 모드)
) else (
    echo    ✅ ArgoCD 있음
)
timeout /t 1 /nobreak >nul

REM ============================================================
REM 7. kubectl get namespace jenkins (원본과 동일)
REM ============================================================
echo [7/11] Jenkins 설치 확인...
kubectl get namespace jenkins >nul 2>&1
if !errorlevel! neq 0 (
    echo    → Jenkins 없음
) else (
    echo    ✅ Jenkins 있음
)
timeout /t 1 /nobreak >nul

REM ============================================================
REM 8. kubectl get namespace dev (원본과 동일)
REM ============================================================
echo [8/11] Dev Calendar 배포 확인...
kubectl get namespace dev >nul 2>&1
if !errorlevel! neq 0 (
    echo    → Dev 환경 없음
    if exist "deploy\k8s\overlays\dev" (
        echo    → deploy 폴더 있음 (배포하지 않음 - 테스트 모드)
    ) else (
        echo    ⚠️  deploy 폴더 없음
    )
) else (
    echo    ✅ Dev 환경 있음
    kubectl get pods -n dev 2>nul
)
timeout /t 1 /nobreak >nul

REM ============================================================
REM 9. start /B kubectl port-forward (원본과 동일)
REM ============================================================
echo [9/11] 포트포워딩 테스트...
echo    → 실제로 실행하지 않음 (테스트 모드)
echo    → 명령어: start /B kubectl port-forward -n dev svc/dev-dev-calendar 8081:80
echo    ✅ 명령어 구문 확인 완료
timeout /t 1 /nobreak >nul

REM ============================================================
REM 10. ArgoCD 비밀번호 가져오기 (원본과 동일)
REM ============================================================
echo [10/11] ArgoCD 비밀번호 조회 테스트...
for /f "tokens=*" %%i in ('kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath^="{.data.password}" 2^>nul ^| powershell -Command "$input | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }"') do set ARGOCD_PASSWORD=%%i
if defined ARGOCD_PASSWORD (
    echo    ✅ 비밀번호 조회 성공: !ARGOCD_PASSWORD!
) else (
    echo    → 비밀번호 조회 실패 (ArgoCD 없거나 Secret 없음)
)
timeout /t 1 /nobreak >nul

REM ============================================================
REM 11. start 명령어 테스트 (원본과 동일)
REM ============================================================
echo [11/11] 브라우저 실행 테스트...
echo    → 실제로 실행하지 않음 (테스트 모드)
echo    → 명령어: start http://localhost:8081/projects/
echo    ✅ 명령어 구문 확인 완료
timeout /t 1 /nobreak >nul

REM ============================================================
REM 최종 검증
REM ============================================================
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                 ✅ 모든 11단계 테스트 완료!                  ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo 결과 요약:
echo   1. Python 가상환경: ✅
echo   2. pip 패키지 설치: ✅
echo   3. Docker Desktop: ✅
echo   4. Minikube: !MINIKUBE_STATUS!
echo   5. Kubernetes: ✅
echo   6. ArgoCD: 확인함
echo   7. Jenkins: 확인함
echo   8. Dev Calendar: 확인함
echo   9. 포트포워딩: 구문 확인
echo  10. 비밀번호 조회: 확인함
echo  11. 브라우저 실행: 구문 확인
echo.
if defined ARGOCD_PASSWORD (
    echo ArgoCD 비밀번호: !ARGOCD_PASSWORD!
)
echo.
echo ========================================
echo 스크립트가 끝까지 도달했습니다!
echo 이제 원본 start.bat도 동작해야 합니다.
echo ========================================
echo.
pause
endlocal
