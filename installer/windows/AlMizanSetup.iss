#define MyAppVersion "1.0.0"
[Setup]
AppId={{B6282E70-9B42-481B-A17D-32C475EBC762}
AppName=Al-Mizan ERP
AppVersion={#MyAppVersion}
AppPublisher=Al-Mizan ERP
DefaultDirName={autopf}\AlMizanERP
DefaultGroupName=Al-Mizan ERP
OutputDir=..\output
OutputBaseFilename=AlMizanERP-Setup-Windows-x64
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
PrivilegesRequired=admin
WizardStyle=modern
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\AlMizanERP.exe
SetupLogging=yes
CloseApplications=no
RestartApplications=no
LicenseFile=THIRD_PARTY_NOTICES.txt
[Languages]
Name: "arabic"; MessagesFile: "Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"
[Files]
Source: "..\stage\installer\*"; DestDir: "{app}\installer"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\stage\notices\*"; DestDir: "{app}\notices"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\stage\app\*"; DestDir: "{app}\app"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: IsServerInstall
Source: "..\stage\runtime\*"; DestDir: "{app}\runtime"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: IsServerInstall
Source: "..\stage\AlMizanERP.exe"; DestDir: "{app}"; Flags: ignoreversion; Check: IsServerInstall
Source: "..\stage\build-manifest.json"; DestDir: "{app}"; Flags: ignoreversion
[Icons]
Name: "{commondesktop}\Al-Mizan ERP"; Filename: "{app}\Open-AlMizan.url"
Name: "{group}\Al-Mizan ERP"; Filename: "{app}\Open-AlMizan.url"
Name: "{group}\Connection Information"; Filename: "{app}\Connection-Info.txt"
Name: "{group}\Uninstall"; Filename: "{uninstallexe}"
[UninstallDelete]
Type: files; Name: "{app}\Open-AlMizan.url"
Type: files; Name: "{app}\Connection-Info.txt"
Type: files; Name: "{app}\AlMizanERP.xml"
Type: files; Name: "{app}\installation.json"
Type: filesandordirs; Name: "{app}\mysql"
[Code]
var
 ModePage: TInputOptionWizardPage;
 DbPage: TInputOptionWizardPage;
 ConnectionPage, CompanyPage, PasswordPage, NetworkPage, UrlPage: TInputQueryWizardPage;
 UseAnswerFile: String;
 ExistingInstall: Boolean;
function FileMode(FileName: String): String;
var Text: AnsiString; Clean: String;
begin
 Result:='';
 if LoadStringFromFile(FileName,Text) then begin
  Clean:=String(Text);StringChangeEx(Clean,' ','',True);StringChangeEx(Clean,#13,'',True);StringChangeEx(Clean,#10,'',True);StringChangeEx(Clean,#9,'',True);
  if Pos('"mode":"client"',Clean)>0 then Result:='client' else if Pos('"mode":"server"',Clean)>0 then Result:='server' else if Pos('"mode":"standalone"',Clean)>0 then Result:='standalone';
 end;
end;
function ModeName: String;
var Previous: String;
begin
 Previous:=FileMode(ExpandConstant('{app}\installation.json'));
 if Previous='' then Previous:=FileMode(ExpandConstant('{commonappdata}\AlMizanERP\config.json'));
 if Previous<>'' then begin Result:=Previous;exit;end;
 if ModePage.SelectedValueIndex=1 then Result:='server'
 else if ModePage.SelectedValueIndex=2 then Result:='client' else Result:='standalone';
end;
function IsServerInstall: Boolean;
begin Result := ModeName <> 'client'; end;
function EscapeJson(Value: String): String;
begin
 StringChangeEx(Value,'\','\\',True); StringChangeEx(Value,'"','\"',True);
 StringChangeEx(Value,#13,'\r',True); StringChangeEx(Value,#10,'\n',True); StringChangeEx(Value,#9,'\t',True); Result:=Value;
end;
function J(Value: String): String;
begin Result:='"'+EscapeJson(Value)+'"'; end;
procedure InitializeWizard;
begin
 UseAnswerFile:=ExpandConstant('{param:ConfigFile|}');
 ModePage:=CreateInputOptionPage(wpSelectDir,'طريقة تشغيل البرنامج','اختر دور هذا الكمبيوتر','الموظفون يتصلون بالسيرفر من المتصفح، ولا يحتاجون قاعدة بيانات محلية.',True,False);
 ModePage.Add('جهاز مستقل — البرنامج وقاعدة البيانات على هذا الكمبيوتر');
 ModePage.Add('سيرفر شبكة — يستقبل اتصالات أجهزة الموظفين داخل الشبكة');
 ModePage.Add('جهاز موظف — اختصار للاتصال بسيرفر موجود'); ModePage.SelectedValueIndex:=0;
 if FileMode(UseAnswerFile)='client' then ModePage.SelectedValueIndex:=2 else if FileMode(UseAnswerFile)='server' then ModePage.SelectedValueIndex:=1;
 NetworkPage:=CreateInputQueryPage(ModePage.ID,'إعدادات التشغيل','بورت تطبيق الويب','البورت الافتراضي 4000. في وضع السيرفر يسمح بالاتصال من الشبكة المحلية الخاصة فقط.');NetworkPage.Add('بورت البرنامج:',False);NetworkPage.Values[0]:='4000';
 DbPage:=CreateInputOptionPage(NetworkPage.ID,'قاعدة البيانات','اختر إعداد MySQL','القاعدة الخاصة تستخدم بورت 3307، ولا تغير MySQL الموجود على الجهاز. تنزيل MySQL جديد يحتاج إنترنت أثناء التثبيت.',True,False);
 DbPage.Add('تنزيل وتهيئة MySQL خاص بالبرنامج تلقائياً');DbPage.Add('سيرفر MySQL موجود — إنشاء شركة جديدة في قاعدة فارغة');DbPage.Add('ربط قاعدة ميزان موجودة — الاحتفاظ بالشركة والمستخدمين');DbPage.SelectedValueIndex:=0;
 ConnectionPage:=CreateInputQueryPage(DbPage.ID,'اتصال MySQL الموجود','بيانات الاتصال بقاعدة ERP','استخدم حساباً خاصاً بالتطبيق له صلاحيات القاعدة. لن تتغير بيانات الشركة أو كلمات مرور المستخدمين في قاعدة موجودة.');
 ConnectionPage.Add('المضيف:',False);ConnectionPage.Add('البورت:',False);ConnectionPage.Add('اسم القاعدة:',False);ConnectionPage.Add('مستخدم MySQL:',False);ConnectionPage.Add('كلمة مرور MySQL:',True);
 ConnectionPage.Values[0]:='127.0.0.1';ConnectionPage.Values[1]:='3306';ConnectionPage.Values[2]:='almizan';ConnectionPage.Values[3]:='almizan_app';
 CompanyPage:=CreateInputQueryPage(ConnectionPage.ID,'بيانات الشركة الجديدة','تستخدم فقط إذا كانت قاعدة ERP فارغة','لا يتم إدخال فواتير أو عملاء تجريبيين. عند الاتصال بقاعدة موجودة تبقى بياناتها كما هي.');
 CompanyPage.Add('اسم الشركة:',False);CompanyPage.Add('عنوان الشركة:',False);CompanyPage.Add('الرقم الضريبي — اختياري:',False);CompanyPage.Add('اسم مدير النظام:',False);CompanyPage.Add('اسم مستخدم المدير — حروف إنجليزية:',False);CompanyPage.Values[4]:='owner';
 PasswordPage:=CreateInputQueryPage(CompanyPage.ID,'حساب مدير النظام','كلمة مرور المدير للقاعدة الجديدة','12 حرفاً على الأقل، ولا تتجاوز 72 بايت. هذه ليست كلمة مرور MySQL.');PasswordPage.Add('كلمة مرور المدير:',True);PasswordPage.Add('تأكيد كلمة المرور:',True);
 UrlPage:=CreateInputQueryPage(PasswordPage.ID,'الاتصال بالسيرفر','عنوان برنامج الميزان على السيرفر','مثال http://SERVER-PC:4000 — يجب أن يكون السيرفر شغالاً وعلى نفس الشبكة.');UrlPage.Add('عنوان السيرفر:',False);UrlPage.Values[0]:='http://SERVER-PC:4000';
end;
function ShouldSkipPage(PageID: Integer): Boolean;
begin
 ExistingInstall:=FileExists(ExpandConstant('{app}\installation.json')) or FileExists(ExpandConstant('{commonappdata}\AlMizanERP\config.json'));
 Result:=(UseAnswerFile<>'') or ExistingInstall;
 if Result then exit;
 if PageID=UrlPage.ID then Result:=ModeName<>'client'
 else if (PageID=CompanyPage.ID) or (PageID=PasswordPage.ID) then Result:=(ModeName='client') or (DbPage.SelectedValueIndex=2)
 else if (PageID=NetworkPage.ID) or (PageID=DbPage.ID) then Result:=ModeName='client'
 else if PageID=ConnectionPage.ID then Result:=(ModeName='client') or (DbPage.SelectedValueIndex=0);
end;
function NextButtonClick(CurPageID: Integer): Boolean;
var Port: Integer;
begin
 Result:=True;
 if CurPageID=NetworkPage.ID then begin Port:=StrToIntDef(NetworkPage.Values[0],0);Result:=(Port>=1024) and (Port<=65535);if not Result then MsgBox('أدخل بورت بين 1024 و65535.',mbError,MB_OK);end;
 if CurPageID=CompanyPage.ID then begin
  Result:=(Trim(CompanyPage.Values[0])<>'') and (Trim(CompanyPage.Values[3])<>'') and (Length(CompanyPage.Values[4])>=3);
  if not Result then MsgBox('أدخل اسم الشركة واسم المدير واسم مستخدم من 3 حروف على الأقل.',mbError,MB_OK);
 end;
 if CurPageID=PasswordPage.ID then begin
  Result:=(Length(PasswordPage.Values[0])>=12) and (Length(UTF8Encode(PasswordPage.Values[0]))<=72) and (PasswordPage.Values[0]=PasswordPage.Values[1]);
  if not Result then MsgBox('اكتب كلمة مرور 12 حرفاً على الأقل، وتأكد من تطابقها.',mbError,MB_OK);
 end;
end;
function RunPowerShell(FileName, Parameters: String; var ExitCode: Integer): Boolean;
begin Result:=Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),'-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "'+FileName+'" '+Parameters,'',SW_HIDE,ewWaitUntilTerminated,ExitCode);end;
function PrepareToInstall(var NeedsRestart: Boolean): String;
var ExitCode: Integer; P: String;
begin
 Result:='';
 { Stop only the ERP service before replacing application files; keep MySQL/data untouched. }
 P:='-NoProfile -NonInteractive -Command "if(Get-Service AlMizanERP -ErrorAction SilentlyContinue){Stop-Service AlMizanERP -Force}"';
 if not Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),P,'',SW_HIDE,ewWaitUntilTerminated,ExitCode) or (ExitCode<>0) then Result:='تعذر إيقاف خدمة البرنامج قبل التحديث.';
end;
procedure CurStepChanged(CurStep: TSetupStep);
var Answers, DataDir, AnswerPath, ConfigSource, ExistingInfo, Mode: String; ExitCode: Integer; IsPrivate: String;
begin
 if CurStep<>ssPostInstall then exit;
 DataDir:=ExpandConstant('{commonappdata}\AlMizanERP');
 AnswerPath:=ExpandConstant('{tmp}\AlMizan-setup.json');
 if UseAnswerFile<>'' then begin
  if not FileCopy(UseAnswerFile,AnswerPath,False) then RaiseException('Cannot read setup configuration file.');
 end else if FileExists(ExpandConstant('{app}\installation.json')) or FileExists(ExpandConstant('{commonappdata}\AlMizanERP\config.json')) then begin
  { Preserve mode/data path from the previous installation, without collecting secrets again. }
  ConfigSource:=ExpandConstant('{app}\installer\Upgrade-Answers.ps1');
  if not RunPowerShell(ConfigSource,'-InstallDir "'+ExpandConstant('{app}')+'" -OutputFile "'+AnswerPath+'"',ExitCode) or (ExitCode<>0) then RaiseException('Cannot read existing installation configuration.');
 end else begin
  if DbPage.SelectedValueIndex=0 then IsPrivate:='true' else IsPrivate:='false';
  Answers:='{"mode":'+J(ModeName)+',"dataDirectory":'+J(DataDir)+',"appPort":'+NetworkPage.Values[0]+',"privateDatabase":'+IsPrivate+',"mysqlHost":'+J(ConnectionPage.Values[0])+',"mysqlPort":'+J(ConnectionPage.Values[1])+',"mysqlDatabase":'+J(ConnectionPage.Values[2])+',"mysqlUser":'+J(ConnectionPage.Values[3])+',"mysqlPassword":'+J(ConnectionPage.Values[4])+',"companyName":'+J(CompanyPage.Values[0])+',"companyAddress":'+J(CompanyPage.Values[1])+',"taxId":'+J(CompanyPage.Values[2])+',"ownerName":'+J(CompanyPage.Values[3])+',"ownerUsername":'+J(CompanyPage.Values[4])+',"ownerPassword":'+J(PasswordPage.Values[0])+',"serverUrl":'+J(UrlPage.Values[0])+'}';
  if not SaveStringToUTF8File(AnswerPath,Answers,False) then RaiseException('Cannot create setup configuration.');
 end;
 if IsServerInstall then begin
  if not Exec(ExpandConstant('{app}\installer\vc_redist.x64.exe'),'/install /quiet /norestart','',SW_HIDE,ewWaitUntilTerminated,ExitCode) or ((ExitCode<>0) and (ExitCode<>1638) and (ExitCode<>3010)) then RaiseException('Microsoft Visual C++ Runtime installation failed.');
 end;
 if not RunPowerShell(ExpandConstant('{app}\installer\Configure-Installation.ps1'),'-InstallDir "'+ExpandConstant('{app}')+'" -InputFile "'+AnswerPath+'"',ExitCode) or (ExitCode<>0) then begin
  DeleteFile(AnswerPath);RaiseException('تعذر إكمال الإعداد. بياناتك الموجودة لم يتم حذفها. راجع سجل التثبيت وخدمة MySQL ثم أعد تشغيل Setup.');
 end;
 DeleteFile(AnswerPath);
end;
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var ExitCode: Integer;
begin
 if CurUninstallStep=usUninstall then
  if not RunPowerShell(ExpandConstant('{app}\installer\Remove-Installation.ps1'),'-InstallDir "'+ExpandConstant('{app}')+'"',ExitCode) or (ExitCode<>0) then RaiseException('تعذر إيقاف الخدمات. لم يتم حذف قاعدة البيانات.');
end;
