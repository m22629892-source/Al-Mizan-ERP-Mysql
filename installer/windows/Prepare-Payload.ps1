$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$root=Resolve-Path (Join-Path $PSScriptRoot '..\..'); Set-Location $root
$stage=Join-Path $root 'installer\stage';$cache=Join-Path $root 'installer\cache'
New-Item -ItemType Directory -Path $stage,$cache,(Join-Path $stage 'runtime'),(Join-Path $stage 'installer'),(Join-Path $stage 'notices') -Force|Out-Null
function Download($Url,$File){if(-not(Test-Path $File)){Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $File}}
$nodeVersion='26.13.0';$nodeFile="node-v$nodeVersion-win-x64.zip";$nodeZip=Join-Path $cache $nodeFile
Download "https://nodejs.org/dist/v$nodeVersion/$nodeFile" $nodeZip
$checks=Join-Path $cache 'SHASUMS256.txt';Download "https://nodejs.org/dist/v$nodeVersion/SHASUMS256.txt" $checks
$line=Get-Content $checks|Where-Object{$_ -match ('\s'+[regex]::Escape($nodeFile)+'$')}
if(-not $line -or (Get-FileHash $nodeZip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $line.Split(' ')[0]){throw 'Node ZIP checksum mismatch'}
Expand-Archive -LiteralPath $nodeZip -DestinationPath (Join-Path $cache 'node') -Force
Copy-Item (Join-Path $cache "node\node-v$nodeVersion-win-x64\node.exe") (Join-Path $stage 'runtime\node.exe') -Force
Copy-Item (Join-Path $cache "node\node-v$nodeVersion-win-x64\LICENSE") (Join-Path $stage 'notices\NODE-LICENSE.txt') -Force
$mysqlVersion='8.4.13';$mysqlUrl="https://cdn.mysql.com/Downloads/MySQL-8.4/mysql-$mysqlVersion-winx64.zip";$mysqlZip=Join-Path $cache "mysql-$mysqlVersion-winx64.zip"
Download $mysqlUrl $mysqlZip
# The installer downloads the vendor archive directly to the customer only when a new private MySQL is selected.
# This keeps Setup small, and avoids redistributing Oracle's database binaries in the ERP installer.
@{version=$mysqlVersion;url=$mysqlUrl;sha256=(Get-FileHash $mysqlZip -Algorithm SHA256).Hash.ToLowerInvariant();folder="mysql-$mysqlVersion-winx64"}|ConvertTo-Json|Set-Content (Join-Path $stage 'installer\mysql-package.json') -Encoding UTF8
Download 'https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW-x64.exe' (Join-Path $stage 'AlMizanERP.exe')
Download 'https://raw.githubusercontent.com/winsw/winsw/v2.12.0/LICENSE.txt' (Join-Path $stage 'notices\WINSW-LICENSE.txt')
Download 'https://aka.ms/vs/17/release/vc_redist.x64.exe' (Join-Path $stage 'installer\vc_redist.x64.exe')
$signature=Get-AuthenticodeSignature (Join-Path $stage 'installer\vc_redist.x64.exe')
if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Microsoft'){throw 'Microsoft VC runtime signature verification failed'}
Copy-Item (Join-Path $PSScriptRoot '*.ps1') (Join-Path $stage 'installer') -Force
Copy-Item (Join-Path $PSScriptRoot 'THIRD_PARTY_NOTICES.txt') (Join-Path $stage 'notices') -Force
& node (Join-Path $PSScriptRoot 'build-payload.mjs'); if($LASTEXITCODE -ne 0){throw 'Application bundle failed'}
Get-ChildItem $stage -Recurse -File|ForEach-Object{@{path=$_.FullName.Substring($stage.Length+1);sha256=(Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}}|ConvertTo-Json|Set-Content (Join-Path $stage 'build-manifest.json') -Encoding UTF8
Write-Host 'Windows installation payload ready.'
