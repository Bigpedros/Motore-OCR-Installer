#define MyAppName "Motore OCR - AI Locale"
#define MyAppVersion "0.1.7"
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
SetupLogging=yes

[Files]
Source: "..\src\runtime-server.mjs"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\src\Avvia-OCR-Runtime.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\src\Configure-Local-AI.cmd"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{userstartup}\Motore OCR Local Runtime"; Filename: "{cmd}"; Parameters: "/d /c ""{app}\Avvia-OCR-Runtime.cmd"""; WorkingDir: "{app}"
Name: "{userprograms}\Motore OCR\Avvia AI Locale"; Filename: "{cmd}"; Parameters: "/d /c ""{app}\Avvia-OCR-Runtime.cmd"""; WorkingDir: "{app}"

[Run]
Filename: "{cmd}"; Parameters: "/d /c ""{app}\Configure-Local-AI.cmd"""; WorkingDir: "{app}"; StatusMsg: "Configurazione AI locale..."; Flags: waituntilterminated
Filename: "{cmd}"; Parameters: "/d /c ""{app}\Avvia-OCR-Runtime.cmd"""; WorkingDir: "{app}"; Description: "Avvia Motore OCR AI Locale"; Flags: postinstall skipifsilent nowait
