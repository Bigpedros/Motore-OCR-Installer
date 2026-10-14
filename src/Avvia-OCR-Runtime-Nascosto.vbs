Set shell = CreateObject("WScript.Shell")
base = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
shell.Run "cmd.exe /d /c """ & base & "\Avvia-OCR-Runtime.cmd""", 0, False
