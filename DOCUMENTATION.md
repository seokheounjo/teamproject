# Dev Calendar - 완전 자동화 배포 시스템

## 📋 목차
1. [프로젝트 개요](#프로젝트-개요)
2. [시스템 아키텍처](#시스템-아키텍처)
3. [핵심 기술 스택](#핵심-기술-스택)
4. [자동화 워크플로우](#자동화-워크플로우)
5. [기술적 도전과제와 해결방안](#기술적-도전과제와-해결방안)
6. [사용 가이드](#사용-가이드)
7. [발전 방향](#발전-방향)

---

## 프로젝트 개요

### 🎯 프로젝트 목적
Dev Calendar는 JIRA 스타일의 프로젝트 관리 도구로, **완전 자동화된 CI/CD 파이프라인**을 통해 개발부터 배포까지 원클릭으로 처리할 수 있는 시스템입니다.

### 🌟 주요 특징
- **원클릭 실행**: `start.bat` 하나로 모든 환경 구성 자동화
- **GitOps 기반 배포**: ArgoCD를 통한 선언적 배포 관리
- **자동 롤백**: 배포 실패 시 자동으로 이전 버전으로 복구
- **멀티 환경 지원**: Dev/Prod 환경 분리 및 독립적 관리
- **완전한 로컬 개발 환경**: Minikube + Docker 기반 쿠버네티스 클러스터

### 📊 프로젝트 범위
```
개발 환경 구성 → CI 파이프라인 → CD 파이프라인 → 모니터링
     ↓              ↓                ↓              ↓
  start.bat    GitHub Actions    ArgoCD         웹 대시보드
```

---

## 시스템 아키텍처

### 전체 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────┐
│                     개발자 워크스테이션                        │
│  ┌─────────────┐                                             │
│  │  start.bat  │ ← 원클릭 실행                                │
│  └──────┬──────┘                                             │
│         ↓                                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  start.ps1 (PowerShell 자동화 스크립트)              │    │
│  │  ├─ Python venv 생성 및 의존성 설치                  │    │
│  │  ├─ Docker Desktop 확인                              │    │
│  │  ├─ Minikube 클러스터 시작                           │    │
│  │  ├─ ArgoCD 설치 및 구성                              │    │
│  │  ├─ Dev Calendar 배포                                │    │
│  │  ├─ 포트포워딩 자동 설정                             │    │
│  │  └─ 웹 브라우저 자동 실행                            │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
│  ┌───────────────────────────────────────────┐              │
│  │  로컬 쿠버네티스 클러스터 (Minikube)       │              │
│  │  ┌─────────────────────────────────────┐  │              │
│  │  │  Namespace: dev                     │  │              │
│  │  │  ├─ Deployment: dev-dev-calendar    │  │              │
│  │  │  ├─ Service: ClusterIP (포트 80)    │  │              │
│  │  │  └─ Pod: Django App                 │  │              │
│  │  └─────────────────────────────────────┘  │              │
│  │  ┌─────────────────────────────────────┐  │              │
│  │  │  Namespace: argocd                  │  │              │
│  │  │  ├─ ArgoCD Server                   │  │              │
│  │  │  ├─ Application Controller          │  │              │
│  │  │  └─ Repo Server                     │  │              │
│  │  └─────────────────────────────────────┘  │              │
│  │  ┌─────────────────────────────────────┐  │              │
│  │  │  Namespace: jenkins (옵션)          │  │              │
│  │  │  └─ Jenkins Server                  │  │              │
│  │  └─────────────────────────────────────┘  │              │
│  └───────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────┘

                           ↓ Git Push

┌─────────────────────────────────────────────────────────────┐
│                       GitHub                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  GitHub Actions (CI 파이프라인)                        │  │
│  │  1. 코드 체크아웃                                      │  │
│  │  2. Docker 이미지 빌드 (Git SHA 태그)                 │  │
│  │  3. GHCR에 푸시                                        │  │
│  │  4. Kustomize 매니페스트 업데이트 (이미지 태그)       │  │
│  │  5. Git 커밋 & 푸시                                    │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

                           ↓ ArgoCD 감지

┌─────────────────────────────────────────────────────────────┐
│              ArgoCD (GitOps CD 파이프라인)                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  1. Git 저장소 모니터링 (3분마다 폴링)                 │  │
│  │  2. 변경 감지 → 자동 동기화                            │  │
│  │  3. 쿠버네티스 리소스 적용                             │  │
│  │  4. 배포 상태 모니터링                                 │  │
│  │  5. 실패 시 자동 롤백                                  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

                           ↓ 배포 완료

┌─────────────────────────────────────────────────────────────┐
│                   운영 환경 (Production)                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Namespace: prod                                    │    │
│  │  ├─ Deployment: prod-prod-calendar (Replicas: 2)   │    │
│  │  ├─ Service: LoadBalancer                          │    │
│  │  └─ Ingress: prod.dev-calendar.local               │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### 컴포넌트별 역할

#### 1. **start.bat / start.ps1**
- 역할: 로컬 개발 환경 완전 자동화
- 기능:
  - Python 가상환경 자동 생성
  - Docker Desktop 실행 확인
  - Minikube 클러스터 자동 시작
  - ArgoCD 자동 설치 및 구성
  - 서비스 자동 배포
  - 웹 브라우저 자동 실행 (Dev Calendar, ArgoCD, Jenkins)

#### 2. **GitHub Actions (CI)**
- 역할: 지속적 통합 (Continuous Integration)
- 워크플로우:
  ```yaml
  triggers: [push, pull_request]
  steps:
    - checkout code
    - build Docker image (tag: git-SHA)
    - push to GitHub Container Registry
    - update Kustomize manifests
    - commit & push changes
  ```

#### 3. **ArgoCD (CD)**
- 역할: 지속적 배포 (Continuous Deployment)
- GitOps 원칙:
  - Git이 단일 진실 공급원(Single Source of Truth)
  - 선언적 쿠버네티스 매니페스트
  - 자동 동기화 및 헬스 체크
  - 자동 롤백 지원

#### 4. **Kustomize**
- 역할: 환경별 쿠버네티스 매니페스트 관리
- 구조:
  ```
  deploy/k8s/
  ├── base/              # 공통 리소스
  │   ├── deployment.yaml
  │   ├── service.yaml
  │   └── namespace.yaml
  └── overlays/
      ├── dev/           # 개발 환경
      │   └── kustomization.yaml (replicas: 1)
      └── prod/          # 운영 환경
          └── kustomization.yaml (replicas: 2)
  ```

---

## 핵심 기술 스택

### 백엔드
- **Django 5.1.1**: Python 웹 프레임워크
- **Django REST Framework**: RESTful API 구현
- **SQLite**: 개발 환경 데이터베이스

### 프론트엔드
- **HTML5/CSS3/JavaScript**: 웹 인터페이스
- **Bootstrap**: 반응형 UI 디자인

### 컨테이너 & 오케스트레이션
- **Docker**: 컨테이너화
- **Kubernetes (Minikube)**: 로컬 쿠버네티스 클러스터
- **Kustomize**: 매니페스트 관리

### CI/CD
- **GitHub Actions**: CI 파이프라인
- **ArgoCD**: GitOps 기반 CD
- **GitHub Container Registry (GHCR)**: 컨테이너 이미지 저장소

### 자동화
- **PowerShell**: Windows 환경 자동화 스크립트
- **Batch Script**: 엔트리포인트

---

## 자동화 워크플로우

### 1. 로컬 개발 환경 구성 (start.bat)

```
사용자 실행: start.bat
         ↓
[1/11] Python 가상환경 확인
├─ venv 존재 확인
└─ 없으면 python -m venv venv 실행
         ↓
[2/11] 의존성 패키지 설치
├─ pip install --upgrade pip
└─ pip install -r requirements.txt
         ↓
[3/11] Docker Desktop 상태 확인
├─ docker info 실행
└─ 실패 시 에러 메시지 및 종료
         ↓
[4/11] Kubernetes 클러스터 연결 확인
├─ kubectl cluster-info 실행
└─ 실패 시 minikube start --driver=docker
         ↓
[5/11] ArgoCD 설치 확인
├─ kubectl get namespace argocd
├─ 없으면 ArgoCD 매니페스트 설치
└─ Pod Ready 상태 대기 (300초 타임아웃)
         ↓
[6/11] Dev Calendar 배포 확인
├─ kubectl get namespace dev
├─ 없으면 kubectl apply -k deploy/k8s/overlays/dev
└─ Pod 준비 대기 (10초)
         ↓
[7/11] ArgoCD 비밀번호 조회
├─ kubectl get secret argocd-initial-admin-secret
├─ Base64 디코딩
└─ 화면에 ID/PW 표시
         ↓
[8/11] 포트포워딩 시작
├─ kubectl port-forward -n dev svc/dev-dev-calendar 8081:80
├─ kubectl port-forward -n argocd svc/argocd-server 8080:443
└─ kubectl port-forward -n jenkins svc/jenkins 8090:8080 (옵션)
         ↓
[9/11] 서비스 준비 대기 (10초)
         ↓
[10/11] 웹 브라우저 자동 실행
├─ http://localhost:8081/projects/ (Dev Calendar)
├─ https://localhost:8080 (ArgoCD)
└─ http://localhost:8090 (Jenkins, 옵션)
         ↓
[11/11] 사용자 대기 (Enter 키)
├─ 포트포워딩 프로세스 종료
└─ 스크립트 종료
```

### 2. CI 파이프라인 (GitHub Actions)

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [master]
  pull_request:
    branches: [master]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to GHCR
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            ghcr.io/${{ github.repository }}:latest
            ghcr.io/${{ github.repository }}:${{ github.sha }}
          build-args: |
            GIT_COMMIT=${{ github.sha }}

      - name: Update Kustomize image tag
        run: |
          cd deploy/k8s/overlays/prod
          kustomize edit set image app=ghcr.io/${{ github.repository }}:${{ github.sha }}

      - name: Commit and push changes
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add deploy/k8s/overlays/prod/kustomization.yaml
          git commit -m "Update image to ${{ github.sha }}"
          git push
```

### 3. CD 파이프라인 (ArgoCD)

```
ArgoCD 동작 흐름:

1. Git 저장소 모니터링
   ├─ 3분마다 폴링 (기본값)
   └─ 변경 감지 시 즉시 동기화

2. 변경 감지
   ├─ Kustomization.yaml 변경 확인
   └─ 새로운 이미지 태그 발견

3. 동기화 시작
   ├─ kubectl apply -k deploy/k8s/overlays/prod
   ├─ Deployment 업데이트
   └─ Rolling Update 수행

4. 헬스 체크
   ├─ Pod Ready 상태 확인
   ├─ Readiness Probe 체크
   └─ Liveness Probe 체크

5. 결과 판정
   ├─ 성공: Synced & Healthy 상태
   └─ 실패: Degraded 상태 → 자동 롤백
```

---

## 기술적 도전과제와 해결방안

### 도전과제 1: Windows 배치 파일 종료 문제

#### 문제 상황
```batch
echo [4/11] Minikube 상태 확인 중...
minikube status >nul 2>&1    # ← 여기서 스크립트 종료
# 이후 코드 실행 안됨
```

Windows 배치 파일에서 `minikube.exe`, `kubectl.exe` 같은 외부 실행 파일을 호출하면 **스크립트가 예기치 않게 종료**되는 문제 발생.

#### 시도한 해결책 (모두 실패)

1. **call 키워드 사용**
   ```batch
   call minikube status >nul 2>&1
   ```
   → 여전히 종료됨

2. **PowerShell 래퍼**
   ```batch
   powershell -Command "& {minikube status | Out-Null; exit $LASTEXITCODE}"
   ```
   → 여전히 종료됨

3. **임시 배치 파일 생성**
   ```batch
   echo minikube start > %TEMP%\start-minikube.bat
   call %TEMP%\start-minikube.bat
   del %TEMP%\start-minikube.bat
   ```
   → 여전히 종료됨

4. **setlocal EnableDelayedExpansion**
   ```batch
   setlocal EnableDelayedExpansion
   minikube status >nul 2>&1
   set RESULT=!errorlevel!
   ```
   → 여전히 종료됨

#### ✅ 최종 해결책: PowerShell 완전 마이그레이션

**해결 방법:**
- 모든 로직을 PowerShell 스크립트(start.ps1)로 재작성
- start.bat은 단순히 PowerShell을 호출하는 래퍼로 변경
- PowerShell은 외부 실행 파일 호출 시 종료 문제 없음

```batch
# start.bat (간소화)
@echo off
chcp 65001 >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { & '%~dp0start.ps1' }"
```

```powershell
# start.ps1 (PowerShell)
minikube start --driver=docker
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Minikube 시작 실패!" -ForegroundColor Red
    exit 1
}
```

**결과:**
- ✅ minikube, kubectl 실행 시 종료 문제 완전 해결
- ✅ 더 강력한 에러 처리
- ✅ Base64 디코딩 등 고급 기능 지원

### 도전과제 2: ArgoCD 자동 로그인

#### 문제 상황
ArgoCD 초기 비밀번호는 쿠버네티스 Secret에 Base64로 인코딩되어 저장됨. 사용자가 수동으로 조회해야 함.

#### 해결책: PowerShell Base64 디코딩

```powershell
# ArgoCD 비밀번호 자동 조회
$argoCdPasswordBase64 = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null

if ($argoCdPasswordBase64) {
    # Base64 디코딩
    $argoCdPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($argoCdPasswordBase64))

    Write-Host "   [OK] ArgoCD 비밀번호 조회 성공!" -ForegroundColor Green
    Write-Host "   -> ID: admin" -ForegroundColor Cyan
    Write-Host "   -> PW: $argoCdPassword" -ForegroundColor Cyan
}
```

**결과:**
- ✅ 비밀번호 자동 조회 및 화면 표시
- ✅ 사용자가 복사만 하면 로그인 가능

### 도전과제 3: 멀티 환경 관리

#### 문제 상황
Dev/Prod 환경마다 다른 설정(레플리카 수, 도메인 등)이 필요

#### 해결책: Kustomize Overlays

```yaml
# deploy/k8s/base/deployment.yaml (공통)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-calendar
spec:
  replicas: 1  # 기본값
  template:
    spec:
      containers:
      - name: app
        image: app  # placeholder

# deploy/k8s/overlays/prod/kustomization.yaml (운영 환경)
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: prod
namePrefix: prod-
resources:
- ../../base
images:
- name: app
  newName: ghcr.io/username/dev-calendar
  newTag: abc123  # CI에서 자동 업데이트
patches:
- patch: |-
    - op: replace
      path: /spec/replicas
      value: 2  # 운영 환경은 2개
  target:
    kind: Deployment
    name: dev-calendar
```

**결과:**
- ✅ 환경별 설정 분리
- ✅ 공통 코드 재사용
- ✅ GitOps 원칙 준수

### 도전과제 4: Docker 이미지 버전 관리

#### 문제 상황
배포 추적 및 롤백을 위해 명확한 버전 관리 필요

#### 해결책: Git SHA 태그 + 버전 정보 임베딩

```dockerfile
# Dockerfile
ARG GIT_COMMIT=unknown
ENV GIT_COMMIT=${GIT_COMMIT}

# 빌드 시:
docker build --build-arg GIT_COMMIT=$(git rev-parse HEAD) .
```

```python
# Django API
@api_view(['GET'])
def version_info(request):
    return Response({
        'version': os.environ.get('GIT_COMMIT', 'unknown'),
        'timestamp': datetime.now().isoformat()
    })
```

**결과:**
- ✅ 웹 UI에서 현재 배포된 버전 확인 가능
- ✅ Git 커밋과 1:1 매핑되어 추적 용이
- ✅ 롤백 시 정확한 버전으로 복구

---

## 사용 가이드

### 필수 요구사항
- Windows 10/11
- Python 3.9+
- Docker Desktop
- Git
- kubectl
- minikube

### 설치 및 실행

#### 1. 저장소 클론
```bash
git clone https://github.com/username/dev-calendar.git
cd dev-calendar
```

#### 2. 원클릭 실행
```bash
start.bat
```

#### 3. 접속 정보
스크립트 실행 후 자동으로 브라우저가 열립니다:

- **Dev Calendar**: http://localhost:8081/projects/
- **ArgoCD**: https://localhost:8080
  - ID: admin
  - PW: (스크립트가 자동으로 표시)
- **Jenkins**: http://localhost:8090 (설치된 경우)

#### 4. 종료
스크립트 실행 창에서 `Enter` 키 → 모든 포트포워딩 자동 종료

### 개발 워크플로우

#### 코드 수정 → 배포 과정

1. **로컬 개발**
   ```bash
   # 코드 수정
   vim dev_calendar/views.py

   # 로컬 테스트
   python manage.py runserver
   ```

2. **Git 커밋 & 푸시**
   ```bash
   git add .
   git commit -m "Add new feature"
   git push origin master
   ```

3. **자동 CI/CD**
   - GitHub Actions가 자동으로 Docker 이미지 빌드
   - GHCR에 푸시
   - Kustomize 매니페스트 업데이트
   - ArgoCD가 변경 감지 및 자동 배포

4. **배포 확인**
   - ArgoCD 대시보드에서 배포 상태 확인
   - Dev Calendar에서 변경사항 확인

---

## 발전 방향

### 단기 개선사항 (1-3개월)

#### 1. 모니터링 & 로깅 시스템 구축
- **Prometheus + Grafana**: 메트릭 수집 및 시각화
- **EFK Stack**: 중앙화된 로그 관리
  - Elasticsearch: 로그 저장
  - Fluentd: 로그 수집
  - Kibana: 로그 검색 및 시각화

```yaml
# monitoring/prometheus.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    scrape_configs:
    - job_name: 'dev-calendar'
      kubernetes_sd_configs:
      - role: pod
```

#### 2. 알림 시스템
- **Slack/Discord 통합**: 배포 실패 시 알림
- **PagerDuty**: 운영 환경 장애 알림

```yaml
# argocd-notifications.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
data:
  service.slack: |
    token: $slack-token
  template.app-deployed: |
    message: |
      Application {{.app.metadata.name}} is now running new version.
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]
```

#### 3. 보안 강화
- **Secrets 관리**: Sealed Secrets 또는 External Secrets Operator
- **이미지 스캔**: Trivy를 CI에 통합
- **네트워크 정책**: 파드 간 통신 제한

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: dev-calendar-netpol
spec:
  podSelector:
    matchLabels:
      app: dev-calendar
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx-ingress
```

### 중기 개선사항 (3-6개월)

#### 4. 데이터베이스 고가용성
- **PostgreSQL 클러스터**: StatefulSet + PVC
- **자동 백업**: CronJob으로 정기 백업
- **읽기 복제본**: Read Replica로 부하 분산

```yaml
# postgresql-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql
spec:
  serviceName: postgresql
  replicas: 3
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

#### 5. 성능 최적화
- **Redis 캐싱**: 자주 조회되는 데이터 캐싱
- **CDN 통합**: 정적 파일 전송 최적화
- **Horizontal Pod Autoscaler**: 부하에 따른 자동 스케일링

```yaml
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: dev-calendar-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: dev-calendar
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

#### 6. 고급 배포 전략
- **Canary 배포**: ArgoCD Rollouts
- **Blue-Green 배포**: 무중단 배포
- **A/B 테스트**: 기능 플래그 기반 테스트

```yaml
# rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: dev-calendar
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 10m}
      - setWeight: 50
      - pause: {duration: 10m}
      - setWeight: 100
```

### 장기 개선사항 (6-12개월)

#### 7. 멀티 클러스터 관리
- **클러스터 페더레이션**: 여러 리전에 배포
- **ArgoCD ApplicationSet**: 여러 클러스터에 동시 배포
- **글로벌 로드밸런싱**: 지리적 근접성 기반 라우팅

```yaml
# applicationset.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: dev-calendar-multicluster
spec:
  generators:
  - list:
      elements:
      - cluster: us-west
        url: https://kubernetes.us-west.example.com
      - cluster: eu-central
        url: https://kubernetes.eu-central.example.com
  template:
    spec:
      source:
        repoURL: https://github.com/username/dev-calendar
        path: deploy/k8s/overlays/{{cluster}}
```

#### 8. AI/ML 통합
- **자동 이상 탐지**: 로그 패턴 분석
- **용량 예측**: 리소스 사용량 예측 및 자동 조정
- **지능형 알림**: 중요 알림 자동 분류

#### 9. 개발자 경험 개선
- **GitOps 대시보드**: 커스텀 웹 대시보드
- **CLI 도구**: 배포/롤백 명령어 단순화
- **개발 환경 템플릿**: Skaffold 또는 Tilt 통합

```yaml
# skaffold.yaml
apiVersion: skaffold/v2beta29
kind: Config
build:
  artifacts:
  - image: dev-calendar
    docker:
      dockerfile: Dockerfile
deploy:
  kubectl:
    manifests:
    - deploy/k8s/overlays/dev/**/*.yaml
```

#### 10. 비용 최적화
- **리소스 할당 분석**: Kubecost 통합
- **Spot 인스턴스 활용**: 운영 환경 비용 절감
- **자동 스케일 다운**: 비즈니스 시간 외 리소스 축소

### 확장 아이디어

#### 멀티 테넌시 지원
- 조직별 네임스페이스 분리
- RBAC 기반 접근 제어
- 리소스 쿼터 관리

#### SaaS 전환
- 사용자 인증/인가 시스템
- 구독 기반 과금 모델
- API 제공 (REST + GraphQL)

#### 모바일 앱 개발
- React Native 또는 Flutter
- 푸시 알림 지원
- 오프라인 모드

---

## 결론

Dev Calendar 프로젝트는 **완전 자동화된 CI/CD 파이프라인**을 구축하여 개발부터 배포까지의 전 과정을 단순화했습니다.

### 핵심 성과
1. ✅ **원클릭 실행**: start.bat 하나로 모든 환경 구성
2. ✅ **GitOps 기반 배포**: 선언적이고 추적 가능한 배포
3. ✅ **자동 롤백**: 배포 실패 시 자동 복구
4. ✅ **멀티 환경 지원**: Dev/Prod 환경 완전 분리

### 학습 포인트
- Windows 배치 파일의 한계와 PowerShell로의 마이그레이션
- GitOps 원칙과 ArgoCD를 통한 실무 적용
- Kustomize를 활용한 환경별 설정 관리
- GitHub Actions를 통한 CI 파이프라인 구축

### 다음 단계
이 프로젝트는 계속 발전할 것이며, 위에서 제시한 발전 방향을 따라 더욱 견고하고 확장 가능한 시스템으로 성장할 것입니다.

---

## 부록

### A. 트러블슈팅 가이드

#### 문제: Docker Desktop이 실행되지 않음
```
[ERROR] Docker Desktop이 실행되지 않았습니다!
```
**해결책:**
1. Docker Desktop 실행
2. 시스템 트레이에서 Docker 아이콘 확인
3. `docker info` 명령어로 확인

#### 문제: Minikube 시작 실패
```
[ERROR] Minikube 시작 실패!
```
**해결책:**
```bash
# 기존 클러스터 삭제 후 재시작
minikube delete
minikube start --driver=docker
```

#### 문제: ArgoCD 비밀번호 조회 실패
```
[WARN] ArgoCD 비밀번호를 가져올 수 없습니다
```
**해결책:**
```bash
# ArgoCD Pod 상태 확인
kubectl get pods -n argocd

# 수동 비밀번호 조회
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### B. 참고 자료
- [ArgoCD 공식 문서](https://argo-cd.readthedocs.io/)
- [Kustomize 공식 문서](https://kustomize.io/)
- [GitHub Actions 문서](https://docs.github.com/en/actions)
- [Kubernetes 공식 문서](https://kubernetes.io/docs/)
- [Django 공식 문서](https://docs.djangoproject.com/)

### C. 라이센스
MIT License

Copyright (c) 2024 Dev Calendar Project

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
