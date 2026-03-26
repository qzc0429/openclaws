#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#ifndef MyOutputBaseFilename
  #define MyOutputBaseFilename "openclaw-installer-windows-setup"
#endif

#define MyAppName "OpenClaw Installer"
#define MyAppPublisher "OpenClaw"
#define MyAppURL "https://openclaw.ai"

[Setup]
AppId={{C2E0BA14-3C4A-4FD1-A3DE-9F3AAB6B253A}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableWelcomePage=yes
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyMemo=yes
DisableReadyPage=yes
DisableFinishedPage=yes
Uninstallable=no
CreateAppDir=no
PrivilegesRequired=admin
ArchitecturesAllowed=x86 x64 arm64
ArchitecturesInstallIn64BitMode=x64 arm64
Compression=lzma2
SolidCompression=yes
OutputDir=..\dist
OutputBaseFilename={#MyOutputBaseFilename}
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\install-openclaw.ps1"; Flags: dontcopy
Source: "..\openclaw-installer-selector.cmd"; Flags: dontcopy

[Code]
function SetEnvironmentVariable(lpName: string; lpValue: string): Boolean;
  external 'SetEnvironmentVariableW@kernel32.dll stdcall';

procedure SetEnv(const Name: string; const Value: string);
begin
  if not SetEnvironmentVariable(Name, Value) then
  begin
    MsgBox('Failed to set environment variable: ' + Name, mbCriticalError, MB_OK);
    Abort;
  end;
end;

procedure CopyEnvIfPresent(const Name: string);
var
  Value: string;
begin
  Value := GetEnv(Name);
  if Value <> '' then
    SetEnv(Name, Value);
end;

procedure RunOpenClawInstaller;
var
  ResultCode: Integer;
  SelectorPath: string;
  CmdLine: string;
begin
  ExtractTemporaryFile('install-openclaw.ps1');
  ExtractTemporaryFile('openclaw-installer-selector.cmd');
  SelectorPath := ExpandConstant('{tmp}\openclaw-installer-selector.cmd');

  CopyEnvIfPresent('OPENCLAW_TEST_MODE');
  CopyEnvIfPresent('OPENCLAW_SKIP_NODE_INSTALL');
  CopyEnvIfPresent('OPENCLAW_INSTALL_URL');
  SetEnv('OPENCLAW_NONINTERACTIVE', '1');
  SetEnv('OPENCLAW_SELECTOR_CHOICE', 'auto');

  CmdLine := '/c ""' + SelectorPath + '""';
  Log('OpenClaw cmd: cmd.exe ' + CmdLine);

  if not Exec(ExpandConstant('{cmd}'), CmdLine, '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode) then
  begin
    MsgBox('Failed to start OpenClaw installer.', mbCriticalError, MB_OK);
    Abort;
  end;

  if ResultCode <> 0 then
  begin
    MsgBox(Format('OpenClaw installer failed (exit code %d).', [ResultCode]), mbCriticalError, MB_OK);
    Abort;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    RunOpenClawInstaller;
  end;
end;
