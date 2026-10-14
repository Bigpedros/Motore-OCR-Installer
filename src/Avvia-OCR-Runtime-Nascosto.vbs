Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
base = fso.GetParentFolderName(WScript.ScriptFullName)
node = shell.ExpandEnvironmentStrings("%ProgramFiles%") & "\nodejs\node.exe"
If Not fso.FileExists(node) Then node = "node.exe"
shell.CurrentDirectory = base
command = """" & node & """ """ & base & "\runtime-server.mjs"""
shell.Run command, 0, False
