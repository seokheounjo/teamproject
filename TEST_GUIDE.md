# start.bat 테스트 가이드

## 🔧 주요 수정사항

### 문제점 1: 가상환경 활성화 시 스크립트 조기 종료
- **원인**: `call venv\Scripts\activate.bat`가 스크립트 종료를 유발
- **해결**: `setlocal EnableDelayedExpansion` + 직접 경로 지정

### 문제점 2: Minikube 명령 시 스크립트 조기 종료
- **원인**: `errorlevel` 변수가 제대로 캡처되지 않음
- **해결**: `!errorlevel!` 지연 확장 사용 + 중간 변수 저장

## 🧪 테스트 방법

### 1단계: 기본 동작 테스트
Windows CMD(명령 프롬프트)를 열고:
```cmd
cd E:\심플프로젝트\cursor\dev-calendar
quick-test.bat
```

예상 결과:
```
테스트 1: 환경 변수 설정
VENV_PYTHON=E:\심플프로젝트\cursor\dev-calendar\venv\Scripts\python.exe

테스트 2: Docker 확인
Docker 상태: 0
Docker 실행 중

테스트 3: Minikube 확인
Minikube 상태: 0
Minikube 실행 중

테스트 4: Kubernetes 확인
Kubernetes 상태: 0

============================================
모든 테스트 완료! 스크립트가 정상 종료됩니다.
============================================
```

### 2단계: 전체 스크립트 테스트
```cmd
cd E:\심플프로젝트\cursor\dev-calendar
start.bat
```

각 단계별 예상 출력:
1. ✅ Python 가상환경 확인
2. ✅ 의존성 패키지 설치
3. ✅ Docker Desktop 확인
4. ✅ Minikube 상태 확인 ← **여기서 종료되면 안 됨!**
5. ✅ Kubernetes 연결
6. ✅ ArgoCD 설치 확인
7. ✅ Jenkins 설치 확인
8. ✅ Dev Calendar 배포
9. ✅ 포트포워딩 시작
10. ✅ 웹 브라우저 자동 실행

## 🔍 핵심 변경 코드

### Before (문제 있는 코드):
```batch
@echo off
echo [🔧] Minikube 상태 확인 중...
minikube status >nul 2>&1
if errorlevel 1 (
    echo Minikube 시작...
    minikube start --driver=docker
)
```
→ **문제**: `minikube status` 실행 후 스크립트가 종료됨

### After (수정된 코드):
```batch
@echo off
setlocal EnableDelayedExpansion
echo [🔧] Minikube 상태 확인 중...
minikube status >nul 2>&1
set MINIKUBE_STATUS=!errorlevel!

if !MINIKUBE_STATUS! neq 0 (
    echo Minikube 시작...
    minikube start --driver=docker
    if !errorlevel! neq 0 (
        echo 실패!
        pause
        exit /b 1
    )
)
```
→ **해결**: `setlocal EnableDelayedExpansion` + `!errorlevel!` 사용

## 📝 체크리스트

실제 Windows CMD에서 다음을 확인:

- [ ] `quick-test.bat` 실행 → 5초 후 자동 종료
- [ ] `test-start.bat` 실행 → 각 단계마다 pause, 끝까지 도달
- [ ] `start.bat` 실행 → "Minikube 상태 확인 중..." 지나서 계속 진행
- [ ] 웹 브라우저 3개 자동 실행 (Dev Calendar, ArgoCD, Jenkins)
- [ ] ArgoCD 비밀번호 화면에 표시
- [ ] 아무 키 누르면 정상 종료

## ✅ 성공 기준

스크립트가 다음까지 도달하면 성공:
```
╔═══════════════════════════════════════════════════════════════╗
║                    ✅ 모든 서비스 실행 완료!                 ║
╚═══════════════════════════════════════════════════════════════╝

📋 접속 정보 (모든 브라우저가 자동으로 열렸습니다):
...
```

## 🐛 문제 발생 시

만약 여전히 종료된다면:
1. `quick-test.bat` 실행 결과를 확인
2. 어느 테스트에서 종료되는지 확인
3. 해당 명령어 앞에 `echo 실행 전...` 추가하여 디버깅
