# 🐛 디버그 단계별 가이드

## 문제: start.bat 실행 시 중간에 창이 꺼짐

어느 부분에서 종료되는지 확인하기 위한 3가지 디버그 도구를 준비했습니다.

---

## 🔍 방법 1: 최소 버전 (추천!)

**가장 간단한 버전. 각 명령어마다 1초 대기하며 실행**

### 실행 방법:
1. Windows 키 누르기
2. "cmd" 입력 후 Enter
3. 다음 명령어 입력:
```cmd
cd E:\심플프로젝트\cursor\dev-calendar
start-minimal.bat
```

### 예상 출력:
```
========================================
   최소 버전 - 한 단계씩 실행
========================================

1. 시작...
1. 시작... (성공)
2. Python 확인...
2. Python 확인... (venv 존재)
3. Docker 확인...
3. Docker 확인... (결과: 0)
4. Minikube 확인 직전...
4-1. minikube status 실행 중...
4-2. minikube status 완료 (결과: 0)
5. kubectl 확인...
5. kubectl 확인... (결과: 0)

========================================
   모든 단계 완료!
========================================

Docker: 0
Minikube: 0
kubectl: 0

스크립트가 여기까지 도달했습니다!
```

### ❌ 만약 중간에 꺼진다면:
- **꺼지기 직전 마지막 메시지**를 확인하세요
- 예: "4-1. minikube status 실행 중..." 이후 꺼졌다면 → minikube 명령어 문제

---

## 🔍 방법 2: 디버그 버전 (로그 파일 생성)

**모든 단계를 로그 파일에 기록**

### 실행 방법:
```cmd
cd E:\심플프로젝트\cursor\dev-calendar
start-debug.bat
```

### 결과 확인:
1. 스크립트 실행 (종료되더라도 괜찮음)
2. `E:\심플프로젝트\cursor\dev-calendar\debug.log` 파일 열기
3. 마지막 줄 확인

### 로그 파일 예시:
```
========== 실행 시작: 2025-01-15 14:30:00 ==========
[단계 1/11] Python 가상환경 확인 중...
   ✅ 가상환경 존재함
[단계 1 완료]
[단계 2/11] 의존성 패키지 확인 중...
   → VENV_PYTHON: E:\심플프로젝트\cursor\dev-calendar\venv\Scripts\python.exe
   → pip install 결과: 0
[단계 2 완료]
[단계 3/11] Docker Desktop 확인
   → Docker 상태: 0
[단계 3 완료]
[단계 4/11] Minikube 확인 시작
   → minikube status 실행...
   → minikube status 결과: 0
[단계 4 완료]
```

**마지막으로 완료된 단계가 문제 지점!**

---

## 🔍 방법 3: 원본 버전 수정

원본 `start.bat`에 echo 추가:

```batch
echo [DEBUG] Minikube 확인 시작
minikube status >nul 2>&1
echo [DEBUG] Minikube 확인 완료
set MINIKUBE_STATUS=!errorlevel!
echo [DEBUG] MINIKUBE_STATUS: !MINIKUBE_STATUS!
```

---

## 📊 문제 패턴별 해결 방법

### 패턴 1: "Docker 확인" 이후 종료
→ **원인**: Docker Desktop이 실행되지 않음
→ **해결**: Docker Desktop 시작 후 다시 실행

### 패턴 2: "Minikube 확인" 이후 종료
→ **원인**: minikube 명령어가 스크립트를 종료시킴
→ **해결**: 아래 명령어를 CMD에서 직접 실행해보기
```cmd
minikube status
echo 결과: %errorlevel%
```

### 패턴 3: 특정 메시지도 없이 바로 종료
→ **원인**: setlocal EnableDelayedExpansion 무시됨
→ **해결**:
1. Windows 10/11 버전 확인
2. CMD 대신 PowerShell에서 실행:
```powershell
cd E:\심플프로젝트\cursor\dev-calendar
cmd /c start-minimal.bat
```

---

## 🎯 다음 단계

### 실행 후 결과 공유:

1. **start-minimal.bat 실행 결과**를 캡처해주세요
   - 어디까지 출력되는지
   - 마지막 메시지가 무엇인지

2. **debug.log 파일 내용**을 공유해주세요
   - 파일 위치: `E:\심플프로젝트\cursor\dev-calendar\debug.log`
   - 마지막 몇 줄만 복사

3. **Windows 버전 확인**:
```cmd
winver
```

이 정보로 정확한 원인을 찾을 수 있습니다!

---

## ⚡ 빠른 체크리스트

실행 전 확인사항:
- [ ] Docker Desktop이 실행 중인가?
- [ ] minikube가 설치되어 있나?
- [ ] kubectl이 설치되어 있나?
- [ ] Windows CMD에서 실행하는가? (Git Bash 아님!)

```cmd
REM 빠른 확인
docker --version
minikube version
kubectl version --client
```

모두 버전이 출력되면 OK!
