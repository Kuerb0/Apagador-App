' Crea un acceso directo "Apagador" en el Escritorio
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
appPath = scriptDir & "\apagador_app.py"
iconPath = scriptDir & "\apagador.ico"

pyw = ""
On Error Resume Next
Set execObj = shell.Exec("where pythonw")
Do While execObj.Status = 0
    WScript.Sleep 100
Loop
salida = execObj.StdOut.ReadAll()
On Error Goto 0

If Len(salida) > 0 Then
    lineas = Split(salida, vbCrLf)
    pyw = Trim(lineas(0))
End If

If pyw = "" Then
    pyw = "pythonw.exe"
End If

desktop = shell.SpecialFolders("Desktop")
Set atajo = shell.CreateShortcut(desktop & "\Apagador.lnk")
atajo.TargetPath = pyw
atajo.Arguments = """" & appPath & """"
atajo.WorkingDirectory = scriptDir
atajo.WindowStyle = 1
If fso.FileExists(iconPath) Then
    atajo.IconLocation = iconPath & ", 0"
Else
    atajo.IconLocation = pyw & ", 0"
End If
atajo.Description = "Programador de apagado"
atajo.Save

MsgBox "Acceso directo Apagador creado/actualizado en el Escritorio.", vbInformation, "Listo"
