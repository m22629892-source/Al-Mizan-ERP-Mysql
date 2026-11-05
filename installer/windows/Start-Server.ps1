param([Parameter(Mandatory)][string]$InstallDir,[Parameter(Mandatory)][string]$DataDir)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Security
$config=Get-Content -LiteralPath (Join-Path $DataDir 'config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$bytes=[Convert]::FromBase64String($config.protectedPassword)
$password=[Text.Encoding]::UTF8.GetString([Security.Cryptography.ProtectedData]::Unprotect($bytes,$null,[Security.Cryptography.DataProtectionScope]::LocalMachine))
$env:MYSQL_HOST=$config.mysqlHost; $env:MYSQL_PORT=[string]$config.mysqlPort; $env:MYSQL_DATABASE=$config.mysqlDatabase; $env:MYSQL_USER=$config.mysqlUser; $env:MYSQL_PASSWORD=$password
$env:MYSQL_POOL_SIZE='10'; $env:PORT=[string]$config.appPort; $env:BIND_HOST=if($config.mode -eq 'server'){'0.0.0.0'}else{'127.0.0.1'}
$env:NODE_ENV='production'; $env:SEED_DEMO_DATA='false'; $env:ALMIZAN_BACKUP_DIR=Join-Path $DataDir 'backups'
Set-Location -LiteralPath (Join-Path $InstallDir 'app')
& (Join-Path $InstallDir 'runtime\node.exe') (Join-Path $InstallDir 'app\server.mjs')
exit $LASTEXITCODE
