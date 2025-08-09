# Windows PowerShell helper: Dokploy + Monitoring SSH tunnel
param(
  [string]$KeyPath = "$env:USERPROFILE\.ssh\netcup",
  [string]$User = "root",
  [string]$Host = "89.58.38.192"
)

Write-Host "Opening SSH tunnel:"
Write-Host " - Dokploy UI  (http://localhost:3000)"
Write-Host " - Grafana     (http://localhost:3001)"
Write-Host " - Prometheus  (http://localhost:9090)"
Write-Host " - cAdvisor    (http://localhost:8080)"

ssh -i "$KeyPath" `
    -L 3000:localhost:3000 `  # Dokploy
    -L 3001:localhost:3001 `  # Grafana
    -L 9090:localhost:9090 `  # Prometheus
    -L 8080:localhost:8080 `  # cAdvisor
    $User@$Host
