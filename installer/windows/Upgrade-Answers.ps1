param([Parameter(Mandatory)][string]$InstallDir,[Parameter(Mandatory)][string]$OutputFile)
$ErrorActionPreference='Stop'
if(Test-Path (Join-Path $InstallDir 'installation.json')){$installation=Get-Content (Join-Path $InstallDir 'installation.json') -Raw -Encoding UTF8|ConvertFrom-Json}
else{$installation=@{dataDirectory=(Join-Path $env:ProgramData 'AlMizanERP')}}
$config=Get-Content (Join-Path $installation.dataDirectory 'config.json') -Raw -Encoding UTF8|ConvertFrom-Json
@{mode=$config.mode;dataDirectory=$installation.dataDirectory;serverUrl=$config.serverUrl}|ConvertTo-Json|Set-Content -LiteralPath $OutputFile -Encoding UTF8
