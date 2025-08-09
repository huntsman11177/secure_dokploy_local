# Windows PowerShell helper: dokploy-tunnel
param(
  [string]$KeyPath = "$env:USERPROFILE\.ssh\ssh_private_key",
  [string]$User = "root",
  [string]$Host = "server_ip",
  [int]$LocalPort = 3000
)

Write-Host "Opening SSH tunnel: localhost:$LocalPort -> $Host:3000"
ssh -i "$KeyPath" -L $LocalPort`:localhost`:3000 $User@$Host