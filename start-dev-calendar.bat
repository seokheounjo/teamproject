@echo off
echo ====================================
echo Dev Calendar 시작 중...
echo ====================================
echo.

REM 포트포워딩 실행 (백그라운드)
echo [1/3] Kubernetes 포트포워딩 시작...
start /B kubectl port-forward -n dev svc/dev-dev-calendar 8081:80

REM 잠시 대기
timeout /t 3 /nobreak >nul

echo [2/3] 웹 브라우저 실행...
start http://localhost:8081

echo [3/3] 완료!
echo.
echo ====================================
echo Dev Calendar가 실행되었습니다!
echo URL: http://localhost:8081
echo.
echo 종료하려면 이 창을 닫으세요.
echo ====================================
echo.

REM 창 유지 (종료 시 포트포워딩도 함께 종료됨)
pause
