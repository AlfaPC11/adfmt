; SPDX-License-Identifier: BSL-1.0

#define MyAppName "adfmt"
#define MyAppPublisher "Alfa"
#define MyAppURL "https://github.com/AlfaPC11/adfmt"
#define MyAppVersion GetEnv("ADFMT_VERSION")
#define MyAppExeName "adfmt.exe"

[Setup]
AppId={{BDFB4D90-3750-499D-B18C-989E17759DCF}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={localappdata}\Programs\adfmt
DefaultGroupName=adfmt
DisableProgramGroupPage=yes
DisableWelcomePage=no
LicenseFile=..\..\LICENSE.txt
OutputDir=..\..\dist
OutputBaseFilename=adfmt-{#MyAppVersion}-windows-x86_64-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
ChangesEnvironment=yes
CloseApplications=yes
RestartApplications=no
MinVersion=10.0
UninstallDisplayName={#MyAppName} {#MyAppVersion}
UninstallDisplayIcon={app}\{#MyAppExeName}
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription=Alfa's D Formatter installer
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

[Tasks]
Name: addtopath; Description: "Add the adfmt installation directory to the user PATH"; \
  GroupDescription: "Command-line integration:"; Flags: checkedonce

[Files]
Source: "..\..\bin\adfmt.exe"; DestDir: "{app}"; DestName: "{#MyAppExeName}"; \
  Flags: ignoreversion
Source: "..\..\LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\PATENTS"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\NOTICE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\adfmt help"; Filename: "{app}\{#MyAppExeName}"; \
  Parameters: "--help"; WorkingDir: "{app}"
Name: "{group}\Uninstall adfmt"; Filename: "{uninstallexe}"

[Run]
Filename: "{cmd}"; Parameters: "/C ""{app}\{#MyAppExeName}"" --version"; \
  Description: "Verify the installed adfmt executable"; Flags: postinstall runhidden nowait

[Code]
const
  EnvironmentKey = 'Environment';
  EnvironmentValue = 'Path';
  AdfmtRegistryKey = 'Software\Alfa\adfmt';
  PathAddedValue = 'PathAddedByInstaller';
  PathEntryValue = 'PathEntry';

function NormalizePathEntry(Value: string): string;
begin
  Result := RemoveQuotes(Trim(Value));
  while (Length(Result) > 3) and (Result[Length(Result)] = '\') do
    Delete(Result, Length(Result), 1);
  Result := Uppercase(Result);
end;

function PathContains(const Paths, Entry: string): Boolean;
var
  Remaining: string;
  Separator: Integer;
  Item: string;
begin
  Result := False;
  Remaining := Paths;
  repeat
    Separator := Pos(';', Remaining);
    if Separator = 0 then
    begin
      Item := Remaining;
      Remaining := '';
    end
    else
    begin
      Item := Copy(Remaining, 1, Separator - 1);
      Delete(Remaining, 1, Separator);
    end;

    if NormalizePathEntry(Item) = NormalizePathEntry(Entry) then
    begin
      Result := True;
      Exit;
    end;
  until Remaining = '';
end;

function AddToUserPath(const Entry: string): Boolean;
var
  Paths: string;
begin
  Result := False;
  if not RegQueryStringValue(HKCU, EnvironmentKey, EnvironmentValue, Paths) then
    Paths := '';

  if PathContains(Paths, Entry) then
    Exit;

  if (Paths <> '') and (Paths[Length(Paths)] <> ';') then
    Paths := Paths + ';';
  RegWriteExpandStringValue(HKCU, EnvironmentKey, EnvironmentValue, Paths + Entry);
  Result := True;
end;

procedure RemoveFromUserPath(const Entry: string);
var
  Paths: string;
  Remaining: string;
  Updated: string;
  Separator: Integer;
  Item: string;
  IsLast: Boolean;
  IsFirst: Boolean;
begin
  if not RegQueryStringValue(HKCU, EnvironmentKey, EnvironmentValue, Paths) then
    Exit;

  Remaining := Paths;
  Updated := '';
  IsFirst := True;
  repeat
    Separator := Pos(';', Remaining);
    if Separator = 0 then
    begin
      Item := Remaining;
      Remaining := '';
      IsLast := True;
    end
    else
    begin
      Item := Copy(Remaining, 1, Separator - 1);
      Delete(Remaining, 1, Separator);
      IsLast := False;
    end;

    if NormalizePathEntry(Item) <> NormalizePathEntry(Entry) then
    begin
      if not IsFirst then
        Updated := Updated + ';';
      Updated := Updated + Item;
      IsFirst := False;
    end;
  until IsLast;

  RegWriteExpandStringValue(HKCU, EnvironmentKey, EnvironmentValue, Updated);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and WizardIsTaskSelected('addtopath') and
     AddToUserPath(ExpandConstant('{app}')) then
  begin
    RegWriteDWordValue(HKCU, AdfmtRegistryKey, PathAddedValue, 1);
    RegWriteStringValue(HKCU, AdfmtRegistryKey, PathEntryValue,
      ExpandConstant('{app}'));
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  PathAdded: Cardinal;
  PathEntry: string;
begin
  if (CurUninstallStep = usUninstall) and
     RegQueryDWordValue(HKCU, AdfmtRegistryKey, PathAddedValue, PathAdded) and
     (PathAdded = 1) then
  begin
    if not RegQueryStringValue(HKCU, AdfmtRegistryKey, PathEntryValue,
      PathEntry) then
      PathEntry := ExpandConstant('{app}');
    RemoveFromUserPath(PathEntry);
    RegDeleteValue(HKCU, AdfmtRegistryKey, PathAddedValue);
    RegDeleteValue(HKCU, AdfmtRegistryKey, PathEntryValue);
    RegDeleteKeyIfEmpty(HKCU, AdfmtRegistryKey);
  end;
end;
