; Inno Setup script for xplayer (Windows x64 installer)
;
; Compiled in CI, e.g.:
;   ISCC.exe /DAppVersion=2.0.2 ^
;            /DSourceDir="...\build\windows\x64\runner\Release" ^
;            /DOutputDir="..." ^
;            windows\installer\xplayer.iss
;
; vc_redist.x64.exe must sit next to this script (release.yml downloads it).
; Bundling + silently installing it fixes the "double-click does nothing"
; problem: a Flutter Windows release exe links against the MSVC runtime, which
; is absent on clean machines.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "."
#endif

#define AppName "xplayer"
#define AppExe "xplayer.exe"
#define AppPublisher "TNT-Likely"
#define AppUrl "https://github.com/TNT-Likely/xplayer"

[Setup]
; Keep this GUID stable across releases so upgrades replace the prior install.
AppId={{B9D5E7A1-3C42-4F8B-A6E0-7D1C2F9048AB}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}
AppUpdatesURL={#AppUrl}/releases
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=xplayer-{#AppVersion}-windows-x64-setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Flutter Windows builds are x64-only.
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
; Program Files + VC++ runtime install both require elevation.
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
; Idempotent: if the runtime is already present this returns quickly. Exit code
; 3010 (reboot pending) is ignored by Inno's [Run] handling.
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Visual C++ Runtime..."
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
