param([Parameter(Mandatory)][string]$SetupPath)
$ErrorActionPreference='Stop'
$installDir='C:\Program Files\AlMizanERP-CI';$dataDir='C:\ProgramData\AlMizanERP-CI';$password='CI-'+[Guid]::NewGuid().ToString('N')+'!'
$answer=Join-Path $env:RUNNER_TEMP 'almizan-answers.json'
@{mode='server';dataDirectory=$dataDir;appPort=14000;privateDatabase=$true;mysqlHost='127.0.0.1';mysqlPort=3307;mysqlDatabase='almizan';mysqlUser='almizan_app';mysqlPassword='';companyName='Installer acceptance company';companyAddress='';taxId='';ownerName='Installer Owner';ownerUsername='install_owner';ownerPassword=$password;serverUrl=''}|ConvertTo-Json|Set-Content $answer -Encoding UTF8
function Run-Setup($Config){
 $args=@('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',"/DIR=$installDir",("/LOG="+(Join-Path $env:RUNNER_TEMP 'almizan-install.log')))
 if($Config){$args+="/ConfigFile=$Config"}
 $quoted=($args|ForEach-Object{'"'+$_+'"'}) -join ' '
 $process=Start-Process -FilePath $SetupPath -ArgumentList $quoted -Wait -PassThru
 if($process.ExitCode -ne 0){throw "Setup failed: $($process.ExitCode)"}
}
function Login{Invoke-RestMethod 'http://127.0.0.1:14000/api/auth/login' -Method Post -ContentType 'application/json' -Body (@{username='install_owner';password=$password}|ConvertTo-Json)}
try{
 Run-Setup $answer
 if((Get-Service AlMizanERP).Status -ne 'Running' -or (Get-Service AlMizanMySQL).Status -ne 'Running'){throw 'Installed services not running'}
 $health=Invoke-RestMethod 'http://127.0.0.1:14000/api/health';if($health.database -ne 'mysql'){throw 'Wrong database backend'}
 $login=Login;if(-not $login.token){throw 'New administrator cannot log in'}
 $headers=@{Authorization='Bearer '+$login.token};$company=Invoke-RestMethod 'http://127.0.0.1:14000/api/company' -Headers $headers
 $invoices=Invoke-RestMethod 'http://127.0.0.1:14000/api/sales/invoices' -Headers $headers
 if($invoices.invoices.Count -ne 0){throw 'Customer installation contains demo invoices'}
 $users=Invoke-RestMethod 'http://127.0.0.1:14000/api/users' -Headers $headers
 if($users.users.Count -ne 1 -or $users.users[0].username -ne 'install_owner'){throw 'Unexpected demo users'}
 $firewall=Get-NetFirewallRule -Name AlMizanERP-LAN;if($firewall.Profile -ne 'Private'){throw 'Firewall is not scoped to Private networks'}
 $before=(Get-FileHash (Join-Path $dataDir 'config.json')).Hash
 Run-Setup ''
 if((Get-FileHash (Join-Path $dataDir 'config.json')).Hash -ne $before){throw 'Upgrade changed saved credentials or mode'}
 $again=Login;if(-not $again.token){throw 'Upgrade did not preserve administrator password'}
 Write-Host 'PASS server install, private MySQL, clean company, custom owner, services, firewall, and upgrade preserving configuration.'
 $uninstall=Start-Process (Join-Path $installDir 'unins000.exe') -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -Wait -PassThru
 if($uninstall.ExitCode -ne 0 -or -not(Test-Path (Join-Path $dataDir 'mysql-data'))){throw 'Uninstall did not preserve database'}
 # Client-only installer is tested against a local HTTP test endpoint; actual two-computer LAN needs a customer-network smoke test.
 $mock=Join-Path $env:RUNNER_TEMP 'almizan-client-mock.cjs'
 "require('http').createServer((req,res)=>{res.setHeader('Content-Type','application/json');res.end(JSON.stringify({status:'ok',database:'mysql'}))}).listen(14001,'127.0.0.1');"|Set-Content $mock -Encoding ASCII
 $mockProcess=Start-Process 'node.exe' -ArgumentList $mock -PassThru
 try{
  Start-Sleep -Seconds 2
  $installDir='C:\Program Files\AlMizanERP-Client-CI';$clientDir='C:\ProgramData\AlMizanERP-Client-CI'
  @{mode='client';dataDirectory=$clientDir;serverUrl='http://127.0.0.1:14001'}|ConvertTo-Json|Set-Content $answer -Encoding UTF8
  Run-Setup $answer
  if((Test-Path (Join-Path $installDir 'runtime\node.exe')) -or (Test-Path (Join-Path $installDir 'app')) -or (Test-Path (Join-Path $clientDir 'mysql-data'))){throw 'Client-only mode installed server components'}
  if(-not (Select-String -Path (Join-Path $installDir 'Open-AlMizan.url') -Pattern '14001' -Quiet)){throw 'Client shortcut address mismatch'}
  Write-Host 'PASS client-only shortcut install without Node.js, application server, or MySQL.'
 }finally{Stop-Process -Id $mockProcess.Id -Force -ErrorAction SilentlyContinue}
}catch{
 Write-Host $_
 Get-ChildItem $dataDir -Filter '*.err' -Recurse -ErrorAction SilentlyContinue|ForEach-Object{Get-Content $_.FullName -Tail 60}
 if(Test-Path (Join-Path $dataDir 'logs')){Get-ChildItem (Join-Path $dataDir 'logs') -File|ForEach-Object{Get-Content $_.FullName -Tail 60}}
 throw
}finally{if(Test-Path $answer){Remove-Item $answer -Force}}
