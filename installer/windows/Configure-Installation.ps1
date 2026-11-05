param([Parameter(Mandatory)][string]$InstallDir,[Parameter(Mandatory)][string]$InputFile)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.Security
function Write-Json($Path,$Object){$Object | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -Encoding UTF8}
function Invoke-Checked($Executable,[string[]]$ArgumentList){ & $Executable @ArgumentList; if($LASTEXITCODE -ne 0){throw "Command failed: $([IO.Path]::GetFileName($Executable)) (exit $LASTEXITCODE)"} }
function Protect-String([string]$Value){[Convert]::ToBase64String([Security.Cryptography.ProtectedData]::Protect([Text.Encoding]::UTF8.GetBytes($Value),$null,[Security.Cryptography.DataProtectionScope]::LocalMachine))}
function New-Password { $bytes=New-Object byte[] 32; $rng=[Security.Cryptography.RandomNumberGenerator]::Create();try{$rng.GetBytes($bytes)}finally{$rng.Dispose()}; -join ($bytes|ForEach-Object{$_.ToString('x2')}) }
function Test-Port([int]$Port){$listener=New-Object Net.Sockets.TcpListener([Net.IPAddress]::Any,$Port);try{$listener.Start();$true}catch{$false}finally{$listener.Stop()}}
function Wait-Health([string]$Url,[int]$Seconds=90){
 for($i=0;$i -lt $Seconds;$i++){try{$response=Invoke-RestMethod -Uri ($Url.TrimEnd('/')+'/api/health') -TimeoutSec 2;if($response.status -eq 'ok' -and $response.database -eq 'mysql'){return}}catch{};Start-Sleep -Seconds 1}
 throw 'Server did not become ready. Check the server address or the service logs.'
}
function Ensure-MySQLFiles([string]$InstallDir,[string]$dataDir){
 $mysqlDir=Join-Path $InstallDir 'mysql'
   $package=Get-Content (Join-Path $InstallDir 'installer\mysql-package.json') -Raw -Encoding UTF8|ConvertFrom-Json
   if(-not (Test-Path (Join-Path $mysqlDir 'bin\mysqld.exe'))){
    $archive=Join-Path $dataDir 'mysql-download.zip'
    if($env:ALMIZAN_MYSQL_ARCHIVE -and (Test-Path $env:ALMIZAN_MYSQL_ARCHIVE)){Copy-Item $env:ALMIZAN_MYSQL_ARCHIVE $archive -Force}
    else{Write-Host 'Downloading MySQL Community Server from Oracle...';Invoke-WebRequest -UseBasicParsing -Uri $package.url -OutFile $archive}
    if((Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $package.sha256){Remove-Item $archive -Force;throw 'MySQL archive checksum mismatch'}
    $expanded=Join-Path $dataDir 'mysql-unpack';Expand-Archive -LiteralPath $archive -DestinationPath $expanded -Force
    Move-Item (Join-Path $expanded $package.folder) $mysqlDir
    Remove-Item $expanded -Force;Remove-Item $archive -Force
   }

}
$answers=$null; $bootstrapFile=$null
try {
 $answers=Get-Content -LiteralPath $InputFile -Raw -Encoding UTF8 | ConvertFrom-Json
 if($answers.mode -notin @('standalone','server','client')){throw 'Invalid installation mode'}
 $dataDir=[Environment]::ExpandEnvironmentVariables([string]$answers.dataDirectory)
 if(-not [IO.Path]::IsPathRooted($dataDir)){throw 'Data directory must be absolute'}
 if([IO.Path]::GetFullPath($dataDir).StartsWith([IO.Path]::GetFullPath($InstallDir),[StringComparison]::OrdinalIgnoreCase)){throw 'Data directory must be outside the application directory'}
 $configPath=Join-Path $dataDir 'config.json'
 New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
 # Administrative setup secrets are not readable by other Windows users.
 Invoke-Checked 'icacls.exe' @($InputFile,'/inheritance:r','/grant:r','*S-1-5-18:F','*S-1-5-32-544:F')
 Invoke-Checked 'icacls.exe' @($dataDir,'/inheritance:r','/grant:r','*S-1-5-18:(OI)(CI)F','*S-1-5-32-544:(OI)(CI)F','*S-1-5-19:(OI)(CI)M')
 Start-Transcript -Path (Join-Path $dataDir 'setup.log') -Append | Out-Null
 $existing=if(Test-Path $configPath){Get-Content -LiteralPath $configPath -Raw -Encoding UTF8|ConvertFrom-Json}else{$null}
 if($existing -and $existing.mode -ne $answers.mode){throw 'Existing installation mode is preserved. Use the original mode when reinstalling.'}
 if($answers.mode -eq 'client'){
  $uri=$null
  if(-not [Uri]::TryCreate([string]$answers.serverUrl,[UriKind]::Absolute,[ref]$uri) -or $uri.Scheme -notin @('http','https') -or $uri.UserInfo -or $uri.Query -or $uri.Fragment -or $uri.AbsolutePath -ne '/'){throw 'Enter a server base URL such as http://SERVER:4000'}
  Wait-Health $uri.AbsoluteUri 8
  Write-Json $configPath @{mode='client';serverUrl=$uri.AbsoluteUri;version=1}
  "[InternetShortcut]`r`nURL=$($uri.AbsoluteUri)" | Set-Content -LiteralPath (Join-Path $InstallDir 'Open-AlMizan.url') -Encoding ASCII
  'Client shortcut installed. No local database or application service is installed.' | Set-Content (Join-Path $InstallDir 'Connection-Info.txt') -Encoding UTF8
  Write-Json (Join-Path $InstallDir 'installation.json') @{dataDirectory=$dataDir;mode='client'}
  exit 0
 }
 $serviceExe=Join-Path $InstallDir 'AlMizanERP.exe'
 if(Get-Service 'AlMizanERP' -ErrorAction SilentlyContinue){Stop-Service 'AlMizanERP' -Force -ErrorAction Stop}
 if($existing){$config=$existing}
 else {
  if(-not (Test-Port ([int]$answers.appPort))){throw 'The application port is already occupied. Choose another port.'}
  $private=[bool]$answers.privateDatabase
  $config=[PSCustomObject]@{version=1;mode=$answers.mode;appPort=[int]$answers.appPort;privateDatabase=$private;mysqlHost=[string]$answers.mysqlHost;mysqlPort=[int]$answers.mysqlPort;mysqlDatabase=[string]$answers.mysqlDatabase;mysqlUser=[string]$answers.mysqlUser;protectedPassword=''}
  if($config.appPort -lt 1024 -or $config.appPort -gt 65535){throw 'Application port must be 1024-65535'}
  if($config.mysqlPort -lt 1 -or $config.mysqlPort -gt 65535){throw 'Invalid MySQL port'}
  if($private){
   $config.mysqlHost='127.0.0.1';$config.mysqlPort=3307;$config.mysqlDatabase='almizan';$config.mysqlUser='almizan_app'
   if(-not (Test-Port 3307) -and -not (Test-Path (Join-Path $dataDir 'private-setup.bin'))){throw 'Private MySQL port 3307 is occupied. Choose the existing MySQL option instead.'}
   $mysqlDir=Join-Path $InstallDir 'mysql';$mysqlData=Join-Path $dataDir 'mysql-data';$ini=Join-Path $dataDir 'my.ini';$initSql=Join-Path $dataDir 'mysql-first-start.sql';$stateFile=Join-Path $dataDir 'private-setup.bin'
   $hasData=Test-Path (Join-Path $mysqlData 'mysql')
   if(Test-Path $stateFile){
    $protected=[Convert]::FromBase64String((Get-Content $stateFile -Raw).Trim())
    $state=[Text.Encoding]::UTF8.GetString([Security.Cryptography.ProtectedData]::Unprotect($protected,$null,[Security.Cryptography.DataProtectionScope]::LocalMachine))|ConvertFrom-Json
    $rootPassword=$state.rootPassword;$appPassword=$state.appPassword
   }elseif($hasData -or (Get-Service 'AlMizanMySQL' -ErrorAction SilentlyContinue)){
    throw 'Existing private MySQL has no recoverable setup state. Restore the original config.json; no database files were modified.'
   }else{
    $rootPassword=New-Password;$appPassword=New-Password
    Protect-String (@{rootPassword=$rootPassword;appPassword=$appPassword}|ConvertTo-Json) | Set-Content $stateFile -Encoding ASCII
    Invoke-Checked 'icacls.exe' @($stateFile,'/inheritance:r','/grant:r','*S-1-5-18:F','*S-1-5-32-544:F')
   }
   New-Item -ItemType Directory -Path $mysqlData -Force | Out-Null
   Ensure-MySQLFiles $InstallDir $dataDir
   "ALTER USER 'root'@'localhost' IDENTIFIED BY '$rootPassword';" | Set-Content -LiteralPath $initSql -Encoding ASCII
   $myBase=$mysqlDir.Replace('\','/');$myData=$mysqlData.Replace('\','/');$myInit=$initSql.Replace('\','/')
   @"
[mysqld]
basedir="$myBase"
datadir="$myData"
bind-address=127.0.0.1
port=3307
mysqlx=OFF
character-set-server=utf8mb4
init-file="$myInit"
"@ | Set-Content -LiteralPath $ini -Encoding ASCII
   $mysqld=Join-Path $mysqlDir 'bin\mysqld.exe'
   if(-not $hasData){Invoke-Checked $mysqld @("--defaults-file=$ini",'--initialize-insecure','--console')}
   $service=Get-CimInstance Win32_Service -Filter "Name='AlMizanMySQL'"
   if($service){
    if(-not $service.PathName.ToLowerInvariant().Contains($mysqld.ToLowerInvariant())){throw 'AlMizanMySQL service belongs to another installation'}
   }else{
    Invoke-Checked $mysqld @('--install','AlMizanMySQL',"--defaults-file=$ini")
    Invoke-Checked 'sc.exe' @('config','AlMizanMySQL','obj=','NT AUTHORITY\LocalService')
   }
   (Protect-String $rootPassword) | Set-Content -LiteralPath (Join-Path $dataDir 'mysql-admin.bin') -Encoding ASCII
   Invoke-Checked 'icacls.exe' @((Join-Path $dataDir 'mysql-admin.bin'),'/inheritance:r','/grant:r','*S-1-5-18:F','*S-1-5-32-544:F')
   Start-Service 'AlMizanMySQL'
   $answers | Add-Member -NotePropertyName rootPassword -NotePropertyValue $rootPassword -Force
   $answers.mysqlPassword=$appPassword;$answers.mysqlHost='127.0.0.1';$answers.mysqlPort=3307;$answers.mysqlDatabase='almizan';$answers.mysqlUser='almizan_app'
  }
  $bootstrapFile=Join-Path $dataDir 'pending-setup.json';Write-Json $bootstrapFile $answers
  Invoke-Checked 'icacls.exe' @($bootstrapFile,'/inheritance:r','/grant:r','*S-1-5-18:F','*S-1-5-32-544:F')
  $ready=$false
  for($attempt=0;$attempt -lt 45;$attempt++){
   & (Join-Path $InstallDir 'runtime\node.exe') (Join-Path $InstallDir 'app\bootstrap.mjs') $bootstrapFile
   if($LASTEXITCODE -eq 0){$ready=$true;break}
   if(-not $private){break};Start-Sleep -Seconds 2
  }
  if(-not $ready){throw 'Database setup failed. Your existing ERP data was not replaced. Check credentials and setup output.'}
  if($private){
   (Get-Content -LiteralPath $ini | Where-Object{$_ -notmatch '^init-file='}) | Set-Content -LiteralPath $ini -Encoding ASCII
   Remove-Item -LiteralPath $initSql -Force
  }
  $config.protectedPassword=Protect-String ([string]$answers.mysqlPassword)
  Write-Json $configPath $config
  if($private -and (Test-Path $stateFile)){Remove-Item $stateFile -Force}
 }
 # Reinstall after uninstall: reuse the same data and credentials, never initialize again.
 if($config.privateDatabase){Ensure-MySQLFiles $InstallDir $dataDir}
 if($config.privateDatabase -and -not (Get-Service 'AlMizanMySQL' -ErrorAction SilentlyContinue)){
  Invoke-Checked (Join-Path $InstallDir 'mysql\bin\mysqld.exe') @('--install','AlMizanMySQL',"--defaults-file=$(Join-Path $dataDir 'my.ini')")
  Invoke-Checked 'sc.exe' @('config','AlMizanMySQL','obj=','NT AUTHORITY\LocalService')
 }
 if($config.privateDatabase){Start-Service 'AlMizanMySQL'}
 foreach($folder in @('logs','backups')){New-Item -ItemType Directory -Path (Join-Path $dataDir $folder) -Force | Out-Null}
 $escape={param($value)[Security.SecurityElement]::Escape($value)}
 $nodeLauncher=&$escape (Join-Path $InstallDir 'installer\Start-Server.ps1');$safeInstall=&$escape $InstallDir;$safeData=&$escape $dataDir;$logs=&$escape (Join-Path $dataDir 'logs')
 $dependency=if($config.privateDatabase){'<depend>AlMizanMySQL</depend>'}else{''}
 @"
<service>
 <id>AlMizanERP</id><name>Al-Mizan ERP</name><description>Al-Mizan ERP application server</description>
 <executable>powershell.exe</executable><arguments>-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$nodeLauncher" -InstallDir "$safeInstall" -DataDir "$safeData"</arguments>
 <workingdirectory>$safeInstall</workingdirectory><startmode>Automatic</startmode><delayedAutoStart>true</delayedAutoStart>
 <serviceaccount><domain>NT AUTHORITY</domain><user>LocalService</user></serviceaccount>
 $dependency<onfailure action="restart" delay="10 sec"/><stoptimeout>20 sec</stoptimeout>
 <logpath>$logs</logpath><log mode="roll-by-size"><sizeThreshold>10240</sizeThreshold><keepFiles>5</keepFiles></log>
</service>
"@ | Set-Content -LiteralPath (Join-Path $InstallDir 'AlMizanERP.xml') -Encoding UTF8
 if(-not (Get-Service 'AlMizanERP' -ErrorAction SilentlyContinue)){Invoke-Checked $serviceExe @('install')}
 Start-Service 'AlMizanERP'
 Wait-Health ("http://127.0.0.1:"+$config.appPort)
 if($config.mode -eq 'server'){
  Remove-NetFirewallRule -Name 'AlMizanERP-LAN' -ErrorAction SilentlyContinue
  New-NetFirewallRule -Name 'AlMizanERP-LAN' -DisplayName 'Al-Mizan ERP - Private LAN' -Direction Inbound -Action Allow -Protocol TCP -LocalPort $config.appPort -Profile Private -RemoteAddress LocalSubnet | Out-Null
 }
 $url='http://localhost:'+$config.appPort
 "[InternetShortcut]`r`nURL=$url" | Set-Content -LiteralPath (Join-Path $InstallDir 'Open-AlMizan.url') -Encoding ASCII
 $links=@("Local: $url","Mode: $($config.mode)")
 if($config.mode -eq 'server'){
  $links+="LAN: http://$($env:COMPUTERNAME):$($config.appPort)"
  Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object{$_.IPAddress -notmatch '^(127\.|169\.254\.)'} | ForEach-Object{$links+="LAN: http://$($_.IPAddress):$($config.appPort)"}
 }
 $links+='Data and backups: '+$dataDir;$links | Set-Content -LiteralPath (Join-Path $InstallDir 'Connection-Info.txt') -Encoding UTF8
 Write-Json (Join-Path $InstallDir 'installation.json') @{dataDirectory=$dataDir;mode=$config.mode}
 Write-Host 'Al-Mizan ERP configured successfully.'
} catch {
 Write-Error $_
 exit 1
} finally {
 try{Stop-Transcript | Out-Null}catch{}
 if($bootstrapFile -and (Test-Path $bootstrapFile)){Remove-Item -LiteralPath $bootstrapFile -Force}
 if(Test-Path -LiteralPath $InputFile){Remove-Item -LiteralPath $InputFile -Force}
}
