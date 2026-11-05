param([Parameter(Mandatory)][string]$InstallDir)
$ErrorActionPreference='Stop'
$info=Join-Path $InstallDir 'installation.json'
if(Test-Path $info){
 $installation=Get-Content $info -Raw -Encoding UTF8|ConvertFrom-Json
 if($installation.mode -ne 'client'){
  if(Get-Service 'AlMizanERP' -ErrorAction SilentlyContinue){& (Join-Path $InstallDir 'AlMizanERP.exe') stop; & (Join-Path $InstallDir 'AlMizanERP.exe') uninstall}
  $config=Get-Content (Join-Path $installation.dataDirectory 'config.json') -Raw -Encoding UTF8|ConvertFrom-Json
  if($config.privateDatabase -and (Get-Service 'AlMizanMySQL' -ErrorAction SilentlyContinue)){
   Stop-Service 'AlMizanMySQL' -Force; & sc.exe delete AlMizanMySQL | Out-Null
  }
  Remove-NetFirewallRule -Name 'AlMizanERP-LAN' -ErrorAction SilentlyContinue
 }
}
# Intentionally preserve all ProgramData databases, credentials, logs and backups.
