param(
  [string]$Namespace = "dev",
  [int]$LocalPort = 8080,
  [int]$RemotePort = 80
)

$ErrorActionPreference = 'Stop'

# Kustomize overlays use namePrefix = <namespace>-
# So Service becomes e.g. dev-dev-calendar / prod-dev-calendar
$serviceBaseName = "dev-calendar"
$serviceName = "$Namespace-$serviceBaseName"

Write-Host "Port-forwarding svc/$serviceName -n $Namespace ${LocalPort}->${RemotePort} ..."
Start-Process powershell -ArgumentList @(
  "-NoProfile",
  "-Command",
  "kubectl port-forward svc/$serviceName -n $Namespace ${LocalPort}:${RemotePort}"
) -WindowStyle Minimized

Start-Sleep -Seconds 2

Start-Process "http://127.0.0.1:$LocalPort/"

