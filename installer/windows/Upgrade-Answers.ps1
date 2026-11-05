param([Parameter(Mandatory)][string]$InstallDir,[Parameter(Mandatory)][string]$OutputFile)
$ErrorActionPreference='Stop'
$installation=Get-Content (Join-Path $InstallDir 'installation.json') -Raw -Encoding UTF8|ConvertFrom-Json
$config=Get-Content (Join-Path $installation.dataDirectory 'config.json') -Raw -Encoding UTF8|ConvertFrom-Json
@{mode=$config.mode;dataDirectory=$installation.dataDirectory;serverUrl=$config.serverUrl}|ConvertTo-Json|Set-Content -LiteralPath $OutputFile -Encoding UTF8
