Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
base = fso.GetParentFolderName(WScript.ScriptFullName)
pathFile = base & "\node-path.txt"
node = ""
If fso.FileExists(pathFile) Then
  Set stream = fso.OpenTextFile(pathFile, 1, False)
  If Not stream.AtEndOfStream Then node = Trim(stream.ReadLine)
  stream.Close
End If
If node = "" Then node = shell.ExpandEnvironmentStrings("%ProgramFiles%") & "\nodejs\node.exe"
If Not fso.FileExists(node) Then node = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Programs\nodejs\node.exe"
If Not fso.FileExists(node) Then node = "node.exe"
shell.CurrentDirectory = base
command = """" & node & """ """ & base & "\runtime-server.mjs"""
shell.Run command, 0, False
