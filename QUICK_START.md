# 🚀 빠른 시작 가이드

## 한 번의 클릭으로 시작하기

### Windows 사용자

프로젝트 폴더에서 아래 .bat 파일 중 하나를 **더블클릭**하세요:

#### 1. `start-quick.bat` (권장 🌟)
- Dev Calendar만 빠르게 실행
- 자동으로 브라우저가 열림
- 가장 간단한 방법!

#### 2. `start-all-services.bat` (전체 서비스)
- Dev Calendar + ArgoCD + Jenkins 모두 실행
- 모든 모니터링 도구 한번에 접속
- 개발/운영 환경 확인에 적합

#### 3. `start-dev-calendar.bat` (기본)
- Dev Calendar 단독 실행
- 기본 포트포워딩만 수행

---

## 접속 URL

실행 후 자동으로 브라우저가 열리지만, 수동으로도 접속 가능합니다:

### 📋 Dev Calendar
**URL:** http://localhost:8081

**주요 기능:**
- 프로젝트 목록 및 생성
- 칸반 보드 (드래그 앤 드롭)
- 프로젝트 대시보드 (통계 & 차트)
- 태스크 관리 (CRUD)
- 댓글 시스템

### 📊 ArgoCD (선택)
**URL:** https://localhost:8080
- **Username:** admin
- **Password:** pBEeoQ5LkfAKSwEg

**기능:** GitOps 배포 상태 모니터링

### 🔧 Jenkins (선택)
**URL:** http://localhost:8090

**기능:** CI/CD 파이프라인 관리

---

## 종료 방법

실행한 .bat 파일 창을 닫으면 자동으로 모든 포트포워딩이 종료됩니다.

또는 명령 프롬프트에서 **Ctrl + C**를 누르세요.

---

## 문제 해결

### "Kubernetes 클러스터에 연결할 수 없습니다"
- Minikube 또는 Kubernetes 클러스터가 실행 중인지 확인
- `minikube status` 명령으로 상태 확인
- 필요시 `minikube start` 실행

### "포트가 이미 사용 중입니다"
기존 포트포워딩이 실행 중일 수 있습니다:
```bash
# 프로세스 확인 및 종료
netstat -ano | findstr :8081
taskkill /PID [PID번호] /F
```

### 브라우저가 자동으로 열리지 않음
수동으로 URL 입력:
- http://localhost:8081

---

## 화면 미리보기

### 1. 프로젝트 목록
![Projects List](docs/screenshots/projects-list.png)
- JIRA 스타일 카드 레이아웃
- 프로젝트 생성 모달
- 상태 배지

### 2. 칸반 보드
![Kanban Board](docs/screenshots/kanban.png)
- 6단계 워크플로우
- 드래그 앤 드롭
- 실시간 검색

### 3. 프로젝트 대시보드
![Dashboard](docs/screenshots/dashboard.png)
- 통계 카드
- Chart.js 차트
- 진행률 시각화

---

## 다음 단계

1. ✅ .bat 파일 실행
2. ✅ 브라우저에서 http://localhost:8081 확인
3. ✅ 새 프로젝트 만들기
4. ✅ 칸반 보드에서 태스크 생성
5. ✅ 드래그 앤 드롭으로 상태 변경
6. ✅ 대시보드에서 진행 상황 확인

---

## 🎯 주요 기능

### ✨ 프로젝트 관리
- 다중 프로젝트 지원
- 프로젝트 기간 설정
- 상태 관리 (진행중/완료/보관)

### 📋 태스크 관리
- 생성/수정/삭제 (CRUD)
- 우선순위 (높음/중간/낮음)
- 스토리 포인트
- 태그 시스템
- 시작일/마감일

### 🎨 칸반 보드
- 6단계 워크플로우
- 드래그 앤 드롭
- 실시간 검색/필터
- 사이드바 네비게이션

### 💬 협업
- 태스크 댓글
- 활동 히스토리

### 📊 대시보드
- 실시간 통계
- 도넛/바 차트
- 완료율 추적

---

## 문의 및 지원

문제가 발생하면 다음을 확인하세요:
1. Kubernetes 클러스터 상태
2. Pod 실행 상태: `kubectl get pods -n dev`
3. 서비스 상태: `kubectl get svc -n dev`
4. ArgoCD 동기화: https://localhost:8080

**Happy Coding! 🚀**
