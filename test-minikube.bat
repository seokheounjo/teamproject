@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

echo ========================================
echo Minikube 명령어 테스트
echo ========================================
echo.

echo 테스트 1: minikube version
minikube version
set ERR1=!errorlevel!
echo 결과: !ERR1!
echo.
pause

echo 테스트 2: call minikube version
call minikube version
set ERR2=!errorlevel!
echo 결과: !ERR2!
echo.
pause

echo 테스트 3: cmd /c minikube version
cmd /c minikube version
set ERR3=!errorlevel!
echo 결과: !ERR3!
echo.
pause

echo 테스트 4: minikube status (redirect)
minikube status >temp_status.txt 2>&1
set ERR4=!errorlevel!
type temp_status.txt
del temp_status.txt
echo 결과: !ERR4!
echo.
pause

echo 테스트 5: call minikube status (redirect)
call minikube status >temp_status2.txt 2>&1
set ERR5=!errorlevel!
type temp_status2.txt
del temp_status2.txt
echo 결과: !ERR5!
echo.

echo ========================================
echo 모든 테스트 완료!
echo ========================================
echo.
echo 테스트 1 (direct): !ERR1!
echo 테스트 2 (call): !ERR2!
echo 테스트 3 (cmd /c): !ERR3!
echo 테스트 4 (redirect): !ERR4!
echo 테스트 5 (call+redirect): !ERR5!
echo.
pause
endlocal
