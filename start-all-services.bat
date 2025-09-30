@echo off
chcp 65001 >nul
cls
echo ╔════════════════════════════════════════════════════════════╗
echo ║          🚀 Dev Calendar - 전체 서비스 시작              ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Kubernetes 상태 확인
echo [📡] Kubernetes 클러스터 연결 확인 중...
kubectl cluster-info >nul 2>&1
if errorlevel 1 (
    echo ❌ Kubernetes 클러스터에 연결할 수 없습니다.
    echo    minikube 또는 클러스터가 실행 중인지 확인하세요.
    pause
    exit /b 1
)
echo ✅ Kubernetes 연결 성공!
echo.

REM 포트포워딩 시작
echo [🔌] 포트포워딩 시작 중...
echo    → Dev Calendar (8081)
start /B kubectl port-forward -n dev svc/dev-dev-calendar 8081:80 2>nul

echo    → ArgoCD (8080)
start /B kubectl port-forward -n argocd svc/argocd-server 8080:443 2>nul

echo    → Jenkins (8090)
start /B kubectl port-forward -n jenkins svc/jenkins 8090:8080 2>nul

echo.
echo [⏳] 서비스 준비 중... (5초)
timeout /t 5 /nobreak >nul

REM 브라우저 열기
echo.
echo [🌐] 웹 브라우저 실행 중...
start http://localhost:8081/projects/
timeout /t 1 /nobreak >nul
start https://localhost:8080
timeout /t 1 /nobreak >nul
start http://localhost:8090

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                    ✅ 모든 서비스 실행 완료              ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo 📋 접속 정보:
echo ┌────────────────────────────────────────────────────────────┐
echo │ Dev Calendar    http://localhost:8081                      │
echo │ ArgoCD          https://localhost:8080                     │
echo │   - ID: admin                                              │
echo │   - PW: pBEeoQ5LkfAKSwEg                                   │
echo │ Jenkins         http://localhost:8090                      │
echo └────────────────────────────────────────────────────────────┘
echo.
echo 💡 팁:
echo    - 모든 창이 열리지 않으면 수동으로 URL을 입력하세요
echo    - ArgoCD는 HTTPS이므로 보안 경고가 나올 수 있습니다
echo.
echo ⚠️  종료하려면 이 창을 닫으세요 (포트포워딩도 함께 종료됨)
echo.
pause
