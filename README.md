# Dev Calendar - Kubernetes CI/CD

FastAPI 기반 개발자 캘린더 애플리케이션. GitHub Actions와 Jenkins를 통한 이중 CI/CD 파이프라인, ArgoCD를 활용한 GitOps 배포.

## 아키텍처

### CI/CD 파이프라인

**Option 1: GitHub Actions (권장)**
```
Push to main → Test → Build Docker Image → Push to GHCR → Update K8s Manifests → ArgoCD Sync
```

**Option 2: Jenkins**
```
Push to main → Test → Build Docker Image → Push to GHCR → Update K8s Manifests → ArgoCD Sync
```

### 배포 환경
- **Dev 환경**: `dev` namespace (1 replica)
- **Prod 환경**: `prod` namespace (2 replicas)

### 자동 버전 관리
- 커밋 SHA를 이미지 태그로 사용
- Kustomize가 자동으로 매니페스트 업데이트
- ArgoCD가 변경사항 감지하여 자동 배포

## 사전 요구사항

### 필수 도구
- Docker
- kubectl
- kustomize
- Kubernetes 클러스터 (로컬: minikube, kind / 클라우드: EKS, GKE, AKS 등)

### GitHub 설정
1. **리포지토리 생성**: `https://github.com/seokheounjo/kub`
2. **GitHub Packages 권한 설정** (Settings → Actions → General → Workflow permissions)
   - "Read and write permissions" 활성화

### Jenkins 설정 (Option 2 선택 시)
1. Jenkins 설치 및 실행
2. 필수 플러그인 설치:
   - Docker Pipeline
   - Git
   - Credentials Binding
3. Credentials 생성 (Jenkins → Manage Jenkins → Credentials)
   - ID: `github-token`
   - Type: Secret text
   - Secret: GitHub Personal Access Token (packages:write, repo 권한)

## 빠른 시작

### 1. 저장소 클론 및 초기 푸시

```bash
cd cursor/dev-calendar
git add -A
git commit -m "Initial commit"
git branch -M main
git push -u origin main
```

### 2. ArgoCD 설치

```bash
# ArgoCD 설치
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ArgoCD CLI 설치 (선택사항)
# macOS
brew install argocd

# Windows
choco install argocd-cli

# ArgoCD 접속 (포트포워딩)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 초기 비밀번호 확인
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 브라우저에서 https://localhost:8080 접속
# Username: admin
# Password: 위에서 확인한 비밀번호
```

### 3. ArgoCD Application 배포

```bash
# Dev 환경 배포
kubectl apply -f deploy/argocd/app-dev.yaml

# Prod 환경 배포
kubectl apply -f deploy/argocd/app-prod.yaml

# 배포 상태 확인
kubectl get applications -n argocd
```

### 4. CI/CD 파이프라인 동작 확인

#### Option 1: GitHub Actions (자동)
- `main` 브랜치에 코드 푸시 시 자동 실행
- Actions 탭에서 실행 상태 확인

#### Option 2: Jenkins
```bash
# Jenkins 파이프라인 생성
# 1. New Item → Pipeline
# 2. Pipeline 설정:
#    - Definition: Pipeline script from SCM
#    - SCM: Git
#    - Repository URL: https://github.com/seokheounjo/kub.git
#    - Script Path: Jenkinsfile
# 3. Build Now 실행
```

## 배포 확인

### 애플리케이션 접속

```bash
# Dev 환경
kubectl port-forward -n dev svc/dev-dev-calendar 8081:80
# http://localhost:8081

# Prod 환경
kubectl port-forward -n prod svc/prod-dev-calendar 8082:80
# http://localhost:8082
```

### 배포 상태 확인

```bash
# Pod 상태
kubectl get pods -n dev
kubectl get pods -n prod

# Service 상태
kubectl get svc -n dev
kubectl get svc -n prod

# ArgoCD 앱 상태
kubectl get applications -n argocd
```

## 업데이트 프로세스

### 1. 코드 변경 및 푸시
```bash
# 코드 수정 후
git add .
git commit -m "feat: add new feature"
git push origin main
```

### 2. 자동 배포 흐름
1. **CI 파이프라인 실행**: GitHub Actions 또는 Jenkins
2. **테스트 실행**: pytest로 단위 테스트
3. **Docker 빌드**: 이미지 빌드 및 GHCR 푸시
   - 태그: `latest`, `{commit-sha}`
4. **매니페스트 업데이트**: Kustomize로 이미지 태그 변경
5. **Git 커밋**: 변경된 매니페스트 자동 커밋/푸시
6. **ArgoCD 동기화**: 자동으로 새 이미지 배포

### 3. 버전 확인
```bash
# Dev 환경 이미지 확인
kubectl get deployment -n dev dev-dev-calendar -o jsonpath='{.spec.template.spec.containers[0].image}'

# Prod 환경 이미지 확인
kubectl get deployment -n prod prod-dev-calendar -o jsonpath='{.spec.template.spec.containers[0].image}'
```

## 트러블슈팅

### 이미지 Pull 실패
```bash
# GitHub Packages가 private인 경우 imagePullSecret 필요
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=seokheounjo \
  --docker-password=<GITHUB_TOKEN> \
  -n dev

kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=seokheounjo \
  --docker-password=<GITHUB_TOKEN> \
  -n prod

# Deployment에 imagePullSecrets 추가 (deploy/k8s/base/deployment.yaml)
# spec.template.spec.imagePullSecrets:
#   - name: ghcr-secret
```

### ArgoCD Sync 실패
```bash
# ArgoCD에서 수동 동기화
argocd app sync dev-calendar-dev
argocd app sync dev-calendar-prod

# 또는 ArgoCD UI에서 "Sync" 버튼 클릭
```

### Jenkins 빌드 실패
- Credentials 확인: Jenkins에 `github-token` credential 등록 필요
- Docker 권한 확인: Jenkins 에이전트에 Docker 실행 권한 필요
- Kustomize 설치 확인: Jenkins 에이전트에 kustomize 설치 필요

## 디렉토리 구조

```
dev-calendar/
├── app/                      # FastAPI 애플리케이션
│   ├── api/                  # API 엔드포인트
│   ├── models/               # 데이터 모델
│   ├── services/             # 비즈니스 로직
│   └── main.py              # 앱 진입점
├── deploy/
│   ├── argocd/              # ArgoCD Application 매니페스트
│   │   ├── app-dev.yaml     # Dev 환경
│   │   └── app-prod.yaml    # Prod 환경
│   └── k8s/                 # Kubernetes 매니페스트
│       ├── base/            # 기본 리소스
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── ingress.yaml
│       │   ├── namespace.yaml
│       │   └── kustomization.yaml
│       └── overlays/        # 환경별 오버레이
│           ├── dev/
│           │   └── kustomization.yaml
│           └── prod/
│               └── kustomization.yaml
├── .github/
│   └── workflows/
│       └── ci-cd.yaml       # GitHub Actions CI/CD
├── Dockerfile               # 컨테이너 이미지 빌드
├── Jenkinsfile              # Jenkins 파이프라인
├── requirements.txt         # Python 의존성
└── README.md               # 본 문서
```

## 환경변수

### 애플리케이션
- `PORT`: 서버 포트 (기본값: 8080)
- `DATABASE_URL`: 데이터베이스 URL (기본값: SQLite)

### CI/CD
- `GITHUB_TOKEN`: GitHub Packages 인증 (GitHub Actions에서 자동 제공)
- `CR_PAT`: GitHub Personal Access Token (Jenkins에서 필요)

## 기술 스택

- **Application**: Python 3.12, FastAPI, SQLite
- **Container**: Docker
- **Orchestration**: Kubernetes
- **CI/CD**: GitHub Actions, Jenkins
- **GitOps**: ArgoCD
- **Configuration**: Kustomize
- **Registry**: GitHub Container Registry (GHCR)

## 라이선스

MIT License
# Trigger CI/CD
