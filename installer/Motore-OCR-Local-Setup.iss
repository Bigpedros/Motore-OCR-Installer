#define MyAppName "Motore OCR - AI Locale"
#define MyAppVersion "0.1.0"
#define MyAppPublisher "Bigpedros"

[Setup]
AppId={{A7B26C3C-3E5D-4D7B-A6A8-9D5DCE2C5501}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\MotoreOCR\Runtime
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=Motore-OCR-Local-Setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayName={#MyAppName}

[Files]
Source: "..\src\runtime-server.mjs"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\src\Avvia-OCR-Runtime.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\src\Install-Dependencies.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{userstartup}\Motore OCR Local Runtime"; Filename: "{cmd}"; Parameters: "/c ""{app}\Avvia-OCR-Runtime.cmd"""; WorkingDir: "{app}"

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-Dependencies.ps1"""; WorkingDir: "{app}"; Flags: waituntilterminated
Filename: "{cmd}"; Parameters: "/c ""{app}\Avvia-OCR-Runtime.cmd"""; WorkingDir: "{app}"; Flags: postinstall skipifsilent
