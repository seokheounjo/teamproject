@echo off
REM 빠른 시작 - Dev Calendar만 실행
echo Dev Calendar 시작 중...
start /B kubectl port-forward -n dev svc/dev-dev-calendar 8081:80 2>nul
timeout /t 3 /nobreak >nul
start http://localhost:8081/projects/
echo.
echo 실행 완료! 브라우저가 열립니다.
echo 종료하려면 이 창을 닫으세요.
pause
