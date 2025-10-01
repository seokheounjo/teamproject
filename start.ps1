# PowerShell 스크립트 - 배치 파일 종료 문제 완전 우회

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# UTF-8 인코딩 강제 설정 (한글 표시)
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# 콘솔 제목 설정
$Host.UI.RawUI.WindowTitle = "Dev Calendar 시작 스크립트"

Clear-Host
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "              Dev Calendar - 시작 스크립트                    " -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. Python 가상환경 확인
# ============================================================
Write-Host "[1/11] Python 가상환경 확인 중..." -ForegroundColor Yellow
if (Test-Path "venv") {
    Write-Host "   [OK] 가상환경이 이미 존재합니다." -ForegroundColor Green
} else {
    Write-Host "   -> 가상환경을 생성합니다..." -ForegroundColor Gray
    python -m venv venv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   [ERROR] 가상환경 생성 실패!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "   [OK] 가상환경 생성 완료!" -ForegroundColor Green
}
Write-Host ""

# ============================================================
# 2. 의존성 설치
# ============================================================
Write-Host "[2/11] 의존성 패키지 확인 중..." -ForegroundColor Yellow
$venvPip = ".\venv\Scripts\pip.exe"

if (Test-Path $venvPip) {
    Write-Host "   -> 가상환경 활성화 완료!" -ForegroundColor Gray
    if (Test-Path "requirements.txt") {
        Write-Host "   -> 필요한 패키지를 설치합니다..." -ForegroundColor Gray
        & $venvPip install -q --upgrade pip 2>$null
        & $venvPip install -q -r requirements.txt
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   [OK] 패키지 설치 완료!" -ForegroundColor Green
        } else {
            Write-Host "   [WARN] 일부 패키지 설치 실패" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# ============================================================
# 3. Docker 확인
# ============================================================
Write-Host "[3/11] Docker Desktop 상태 확인 중..." -ForegroundColor Yellow
docker info 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   [ERROR] Docker Desktop이 실행되지 않았습니다!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "   [OK] Docker Desktop 실행 중!" -ForegroundColor Green
Write-Host ""

# ============================================================
# 4. Kubernetes 클러스터 확인
# ============================================================
Write-Host "[4/11] Kubernetes 클러스터 연결 확인 중..." -ForegroundColor Yellow
kubectl cluster-info 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   -> Kubernetes 클러스터에 연결할 수 없습니다." -ForegroundColor Gray
    Write-Host "   -> Minikube를 시작합니다..." -ForegroundColor Gray
    Write-Host "   [WAIT] 시간이 걸릴 수 있습니다 (1~3분)..." -ForegroundColor Yellow

    minikube start --driver=docker
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   [ERROR] Minikube 시작 실패!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "   [OK] Minikube 시작 완료!" -ForegroundColor Green
} else {
    Write-Host "   [OK] Kubernetes 연결 성공!" -ForegroundColor Green
}
Write-Host ""

# ============================================================
# 5. ArgoCD 설치 확인
# ============================================================
Write-Host "[5/11] ArgoCD 설치 확인 중..." -ForegroundColor Yellow
kubectl get namespace argocd 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   -> ArgoCD가 설치되지 않았습니다. 설치합니다..." -ForegroundColor Gray
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    Write-Host "   [WAIT] ArgoCD Pod가 준비될 때까지 대기 중..." -ForegroundColor Yellow
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   [OK] ArgoCD 설치 완료!" -ForegroundColor Green
    } else {
        Write-Host "   [WARN] ArgoCD 설치 시간 초과. 계속 진행합니다..." -ForegroundColor Yellow
    }
} else {
    Write-Host "   [OK] ArgoCD가 이미 설치되어 있습니다." -ForegroundColor Green
}
Write-Host ""

# ============================================================
# 6. Dev Calendar 배포 확인
# ============================================================
Write-Host "[6/11] Dev Calendar 배포 확인 중..." -ForegroundColor Yellow
kubectl get namespace dev 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   -> Dev 환경이 없습니다. 배포합니다..." -ForegroundColor Gray
    if (Test-Path "deploy\k8s\overlays\dev") {
        kubectl apply -k deploy/k8s/overlays/dev
        Write-Host "   [WAIT] Pod가 준비될 때까지 대기 중..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        Write-Host "   [OK] 배포 완료!" -ForegroundColor Green
    }
} else {
    Write-Host "   [OK] Dev 환경이 이미 존재합니다." -ForegroundColor Green
    kubectl get pods -n dev 2>$null
}
Write-Host ""

# ============================================================
# 7. ArgoCD 비밀번호 조회
# ============================================================
Write-Host "[7/11] ArgoCD 비밀번호 조회 중..." -ForegroundColor Yellow
$argoCdPasswordBase64 = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
if ($argoCdPasswordBase64) {
    $argoCdPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($argoCdPasswordBase64))
    Write-Host "   [OK] ArgoCD 비밀번호 조회 성공!" -ForegroundColor Green
    Write-Host "   -> ID: admin" -ForegroundColor Cyan
    Write-Host "   -> PW: $argoCdPassword" -ForegroundColor Cyan
} else {
    Write-Host "   [WARN] ArgoCD 비밀번호를 가져올 수 없습니다." -ForegroundColor Yellow
}
Write-Host ""

# ============================================================
# 8. 포트포워딩 시작
# ============================================================
Write-Host "[8/11] 포트포워딩 시작 중..." -ForegroundColor Yellow
Write-Host "   -> Dev Calendar (8081)" -ForegroundColor Gray
Start-Process -FilePath "kubectl" -ArgumentList "port-forward -n dev svc/dev-dev-calendar 8081:80" -WindowStyle Hidden

Write-Host "   -> ArgoCD (8080)" -ForegroundColor Gray
Start-Process -FilePath "kubectl" -ArgumentList "port-forward -n argocd svc/argocd-server 8080:443" -WindowStyle Hidden

kubectl get svc -n jenkins jenkins 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   -> Jenkins (8090)" -ForegroundColor Gray
    Start-Process -FilePath "kubectl" -ArgumentList "port-forward -n jenkins svc/jenkins 8090:8080" -WindowStyle Hidden
}

Write-Host ""
Write-Host "[9/11] 서비스 준비 중... (10초)" -ForegroundColor Yellow
Start-Sleep -Seconds 10

# ============================================================
# 9. 웹 브라우저 실행
# ============================================================
Write-Host ""
Write-Host "[10/11] 웹 브라우저 실행 중..." -ForegroundColor Yellow

Write-Host "   -> Dev Calendar 열기..." -ForegroundColor Gray
Start-Process "http://localhost:8081/projects/"
Start-Sleep -Seconds 1

Write-Host "   -> ArgoCD 웹 UI 열기..." -ForegroundColor Gray
Start-Process "https://localhost:8080"
Start-Sleep -Seconds 1

kubectl get svc -n jenkins jenkins 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   -> Jenkins 웹 UI 열기..." -ForegroundColor Gray
    Start-Process "http://localhost:8090"
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host "                    모든 서비스 실행 완료!                    " -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "접속 정보:" -ForegroundColor Cyan
Write-Host "   Dev Calendar: http://localhost:8081/projects/" -ForegroundColor White
Write-Host "   ArgoCD: https://localhost:8080" -ForegroundColor White
if ($argoCdPassword) {
    Write-Host "      - ID: admin" -ForegroundColor Yellow
    Write-Host "      - PW: $argoCdPassword" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "종료하려면 Enter를 누르세요..." -ForegroundColor Yellow
Read-Host

# ============================================================
# 10. 종료 처리
# ============================================================
Write-Host ""
Write-Host "[11/11] 서비스 종료 중..." -ForegroundColor Yellow
Write-Host "   -> 포트포워딩 종료 중..." -ForegroundColor Gray
Get-Process -Name kubectl -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "   [OK] 모든 서비스가 종료되었습니다." -ForegroundColor Green
Start-Sleep -Seconds 2

