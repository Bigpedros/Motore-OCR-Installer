#define MyAppName "Motore OCR - AI Locale"
#define MyAppVersion "0.3.6"
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
Source: "..\src\Avvia-OCR-Runtime-Nascosto.vbs"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\src\Configure-Local-AI.cmd"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{userdesktop}\Avvia AI Motore OCR"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\Avvia-OCR-Runtime-Nascosto.vbs"""; WorkingDir: "{app}"
Name: "{userprograms}\Motore OCR\Avvia AI Locale"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\Avvia-OCR-Runtime-Nascosto.vbs"""; WorkingDir: "{app}"

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "MotoreOCRLocalRuntime"; Flags: deletevalue uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\motoreocr-ai"; ValueType: string; ValueName: ""; ValueData: "URL:Motore OCR AI"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\motoreocr-ai"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\motoreocr-ai\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{sys}\wscript.exe,0"
Root: HKCU; Subkey: "Software\Classes\motoreocr-ai\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{sys}\wscript.exe"" ""{app}\Avvia-OCR-Runtime-Nascosto.vbs"""

[InstallDelete]
Type: files; Name: "{userstartup}\Motore OCR Local Runtime.lnk"

[Run]
Filename: "{cmd}"; Parameters: "/d /c ""{app}\Configure-Local-AI.cmd"""; WorkingDir: "{app}"; StatusMsg: "Configurazione AI locale..."; Flags: waituntilterminated
