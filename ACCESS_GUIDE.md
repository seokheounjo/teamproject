# 서비스 접속 가이드 🚀

모든 서비스가 실행 중입니다! 아래 주소로 각 서비스에 접속할 수 있습니다.

## 📊 모니터링 & 관리 도구

### 1. ArgoCD (GitOps 배포 관리)
**URL:** https://localhost:8080

**접속 정보:**
- Username: `admin`
- Password: `pBEeoQ5LkfAKSwEg`

**기능:**
- Dev/Prod 환경 배포 상태 실시간 모니터링
- 애플리케이션 동기화 상태 확인
- Git 커밋별 배포 히스토리
- 수동 동기화 및 롤백 기능

**확인 사항:**
- ✅ `dev-calendar-dev` (dev 환경)
- ✅ `dev-calendar-prod` (prod 환경)
- 상태: Synced & Healthy

---

### 2. Jenkins (CI/CD 파이프라인)
**URL:** http://localhost:8090

**기능:**
- CI/CD 파이프라인 구성 (GitHub Actions 대체)
- 빌드 히스토리 확인
- 수동 빌드 트리거
- 파이프라인 로그 모니터링

**설정 방법:**
1. Jenkins 초기 설정 완료 필요
2. GitHub 연동 설정
3. Jenkinsfile 기반 파이프라인 생성

---

## 🎯 Dev Calendar 애플리케이션

### 3. Dev 환경 (개발)
**URL:** http://localhost:8081

**접속 방법:**
```bash
kubectl port-forward -n dev svc/dev-dev-calendar 8081:80
```

**특징:**
- 1개 레플리카
- 개발/테스트 환경
- 실시간 코드 변경 반영 테스트

---

### 4. Prod 환경 (운영)
**URL:** http://localhost:8082

**접속 방법:**
```bash
kubectl port-forward -n prod svc/prod-dev-calendar 8082:80
```

**특징:**
- 2개 레플리카 (HA 구성)
- 프로덕션 환경
- 로드밸런싱

---

## 🎨 Dev Calendar 주요 화면

### 메인 페이지 (/)
- 자동으로 Project 1 칸반 보드로 리다이렉트

### 칸반 보드 (/projects/{id}/kanban)
- 드래그 앤 드롭 태스크 관리
- 상태별 태스크 그룹화 (Backlog, In Progress, Done)
- 실시간 업데이트

### 캘린더 뷰 (/projects/{id}/calendar)
- 태스크 일정 시각화
- 마감일 기반 일정 관리

---

## 🔧 포트포워딩 명령어 모음

```bash
# ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Jenkins
kubectl port-forward svc/jenkins -n jenkins 8090:8080

# Dev Calendar (Dev)
kubectl port-forward -n dev svc/dev-dev-calendar 8081:80

# Dev Calendar (Prod)
kubectl port-forward -n prod svc/prod-dev-calendar 8082:80
```

---

## 📊 상태 확인 명령어

```bash
# ArgoCD 애플리케이션 상태
kubectl get applications -n argocd

# Dev 환경 Pod 상태
kubectl get pods -n dev

# Prod 환경 Pod 상태
kubectl get pods -n prod

# Jenkins Pod 상태
kubectl get pods -n jenkins

# 전체 서비스 확인
kubectl get svc --all-namespaces | grep -E "argocd-server|jenkins|dev-calendar"
```

---

## 🚀 자동 배포 흐름

```
코드 푸시 (master)
    ↓
GitHub Actions 트리거
    ├─ pytest 테스트
    ├─ Docker 빌드
    ├─ GHCR 푸시 (커밋 SHA 태그)
    └─ Kustomize 매니페스트 자동 업데이트
         ↓
ArgoCD 자동 감지
    ├─ Dev 환경 자동 배포
    └─ Prod 환경 자동 배포
```

**GitHub Actions 확인:**
https://github.com/seokheounjo/teamproject/actions

---

## 💡 유용한 팁

### 1. 새 태스크 생성하기
```bash
curl -X POST "http://localhost:8081/tasks/1/create?title=새%20작업"
```

### 2. 배포 이미지 버전 확인
```bash
# Dev 환경
kubectl get deployment -n dev dev-dev-calendar -o jsonpath='{.spec.template.spec.containers[0].image}'

# Prod 환경
kubectl get deployment -n prod prod-dev-calendar -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### 3. ArgoCD에서 수동 동기화
```bash
# CLI 사용
argocd app sync dev-calendar-dev
argocd app sync dev-calendar-prod

# 또는 UI에서 "Sync" 버튼 클릭
```

### 4. 로그 확인
```bash
# Dev 환경 로그
kubectl logs -n dev -l app.kubernetes.io/name=dev-calendar --tail=100 -f

# Prod 환경 로그
kubectl logs -n prod -l app.kubernetes.io/name=dev-calendar --tail=100 -f
```

---

## 🗄️ 데이터베이스

**타입:** SQLite (경량 DB)
**위치:** 각 Pod 내부 (`/app/run.db`)
**특징:**
- 컨테이너 재시작 시 데이터 초기화
- 개발/테스트용으로 적합
- 프로덕션 환경에서는 PostgreSQL/MySQL 권장

---

## 🔐 보안 정보

**ArgoCD 비밀번호:** `pBEeoQ5LkfAKSwEg`
- 초기 비밀번호 변경 권장
- 변경 방법: ArgoCD UI → User Info → Update Password

**Jenkins:**
- 초기 설정 시 관리자 비밀번호 설정 필요
- GitHub Token Credential 등록 필요 (CI/CD 사용 시)

---

## 📝 다음 단계

1. ✅ ArgoCD에서 배포 상태 확인
2. ✅ Dev Calendar 접속하여 UI 확인
3. ⬜ 태스크 생성/관리 테스트
4. ⬜ 코드 변경 후 자동 배포 테스트
5. ⬜ Jenkins 파이프라인 구성 (선택)

---

**모든 준비 완료! 🎉**
