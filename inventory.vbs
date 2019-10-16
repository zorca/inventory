'Option Explicit

Dim WshShell, KeyPath
Dim ReportFile, strComputer, objWMIService, colItems, objItem, FS, File, Line
Dim ComputerName, Model, Motherboard, Processor, Architecture, RAMType, RAM, HDDModel, HDDSize, Display, OS, WinKey
Dim Manufacturer, Supplier, Category, ModelName, Status, Location
Dim oHTML, ExtIP, DigitalProductId

ReportFile  = "InventoryReport.csv"
strComputer = "."
Model = "Computer"
Model = """" & Model & """"
ModelName = Model
Status = "Agency"
Status = """" & Status & """"

Set oHTML = CreateObject("MSXML2.XMLhttp")
oHTML.Open "GET", "https://api.ipify.org/", False
oHTML.Send
ExtIP =  oHTML.ResponseText

MsgBox(ExtIP)

' Win32_ComputerSystem
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
Set colItems = objWMIService.ExecQuery( _
    "SELECT * FROM Win32_ComputerSystem",,48)
For Each objItem in colItems
    ComputerName = objItem.Name
    'Motherboard = objItem.Manufacturer & " " & objItem.Model
    Architecture = objItem.SystemType
Next
ComputerName = """" & ComputerName & """"
'Motherboard = """" & Motherboard & """"
Architecture = """" & Architecture & """"

' Win32_BaseBoard
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
Set colItems = objWMIService.ExecQuery( _
    "SELECT * FROM Win32_BaseBoard",,48)
For Each objItem in colItems
    Motherboard = objItem.Product
Next
Motherboard = """" & Motherboard & """"

' Win32_Processor HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\CentralProcessor\0\ProcessorNameString

Set WshShell = WScript.CreateObject("WScript.Shell")

KeyPath = "HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\CentralProcessor\0\ProcessorNameString"
Processor = WshShell.RegRead(KeyPath)
Processor = """" & Processor & """"

'Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
'Set colItems = objWMIService.ExecQuery( _
'    "SELECT * FROM Win32_Processor",,48)
'For Each objItem in colItems
'    Processor = objItem.Name
'Next
'Processor = """" & Processor & """"

' Win32_PhysicalMemory
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
Set colItems = objWMIService.ExecQuery( _
    "SELECT * FROM Win32_PhysicalMemory",,48)
For Each objItem in colItems
    RAMType = objItem.Speed
    RAM = RAM + Round(objItem.Capacity / (1024*1024), 2)
Next
RAM = """" & RAM & """"

' Win32_DiskDrive
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
Set colItems = objWMIService.ExecQuery( _
    "SELECT * FROM Win32_DiskDrive where InterfaceType <> 'USB'",,48)
For Each objItem in colItems
    HDDModel = HDDModel + objItem.Model + ", "
    HDDSize = Round(objItem.Size / (1024*1024*1024), 2)
Next
HDDModel = """" & HDDModel & """"
HDDSize = """" & HDDSize & """"

' Win32_LogicalDisk
'Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
'Set colItems = objWMIService.ExecQuery( _
'    "SELECT * FROM Win32_LogicalDisk where DriveType=3",,48)
'For Each objItem in colItems
'    HDD = HDD + Round(objItem.Size / (1024*1024*1024), 2)
'Next
'HDD = """" & HDD & "GB"""

' Win32_DesktopMonitor
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
Set colItems = objWMIService.ExecQuery( _
    "SELECT * FROM Win32_DesktopMonitor",,48)
For Each objItem in colItems
    If isNull(objItem.ScreenWidth) Or isNull(objItem.ScreenHeight) Then
        Display = objItem.Description
    Else
        Display = objItem.Description & " (" & objItem.ScreenWidth & "x" & objItem.ScreenHeight & ")"
    End If
Next
Display = """" & Display & """"

' Win32_OperatingSystem
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
Set colItems = objWMIService.ExecQuery( _
    "SELECT * FROM Win32_OperatingSystem",,48)
For Each objItem in colItems
    OS = objItem.Caption
Next
OS = """" & OS & """"

' Windows Product Key
'Set WshShell = WScript.CreateObject("WScript.Shell")

'KeyPath = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DigitalProductId"
'WinKey = ConvertToKey(WshShell.RegRead(KeyPath))
Set WshShell = CreateObject("WScript.Shell")
KeyPath = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\"
DigitalProductId = WshShell.RegRead(KeyPath & "DigitalProductId")

Win8ProductKey = ConvertToKey(DigitalProductId)

WinKey = """" & Win8ProductKey & """"

Manufacturer = """" & "RESO" & """"

Supplier = """" & "RESO" & """"

Category = """" & "Computer technics" & """"

Line = ComputerName & "," & Model & "," & Motherboard & "," & Processor & "," & RAMType & "," & RAM & "," & HDDModel & "," & HDDSize & "," & Display & "," & OS & "," & WinKey & "," & Manufacturer & "," & Supplier & "," & Category & "," & ModelName & "," & Status
Line = CutSpaces(Line)
'Wscript.Echo Line

' Write to file
Set FS = CreateObject("Scripting.FileSystemObject")
If Not FS.FileExists(ReportFile) then
    Set File = FS.CreateTextFile(ReportFile, False)
    File.Write "Asset Tag,Model,Motherboard,Processor,Memory Type,Memory Value,HD Type,HD Value,Display,OS,Win Key,Manufacturer,Supplier,Category,Model Name,Status" & vbCrLf
Else
    ' Search for existing string
    Set File = FS.OpenTextFile(ReportFile)
    If InStr(File.ReadAll, Line) > 0 Then
        File.Close
        Wscript.Sleep 100
        WScript.Quit 1
    End If

    ' Reopen for appending
    File.Close
    Wscript.Sleep 100
    Set File = FS.OpenTextFile(ReportFile, 8, True) ' 8 - appending
End If

' Write to file
File.Write Line & vbCrLf
File.Close
WScript.Quit 0


Function WmiQuery(strWmiClass,strProperties,strFilter)
    strQuery = "Select " & strProperties & " From " & strWmiClass
    If not strFilter = "" Then strQuery = strQuery & " where " & strFilter
    Set WmiQuery = objWbem.ExecQuery(strQuery)
End Function

Function ExtractKey(KeyInput)
    Dim i, x, Cur, CharWhitelist, KeyOutput, isWin8
    Const KeyOffset = 52
    i = 28
    CharWhitelist = "BCDFGHJKMPQRTVWXY2346789"
    Do
        Cur = 0
        x = 14
        Do
            Cur = Cur * 256
            Cur = KeyInput(x + KeyOffset) + Cur
            KeyInput(x + KeyOffset) = (Cur \ 24) And 255
            Cur = Cur Mod 24
            x = x -1
        Loop While x >= 0
        i = i -1
        KeyOutput = Mid(CharWhitelist, Cur + 1, 1) & KeyOutput
        If (((29 - i) Mod 6) = 0) And (i <> -1) Then
            i = i -1
            KeyOutput = "-" & KeyOutput
        End If
    Loop While i >= 0
    ExtractKey = KeyOutput
End Function

Function ConvertToKey(regKey)
    Dim isWin8, j
    Const KeyOffset = 52
    isWin8 = (regKey(66) \ 6) And 1
    regKey(66) = (regKey(66) And &HF7) Or ((isWin8 And 2) * 4)
    j = 24
    Chars = "BCDFGHJKMPQRTVWXY2346789"
    Do
    Cur = 0
    y = 14
    Do
    Cur = Cur * 256
    Cur = regKey(y + KeyOffset) + Cur
    regKey(y + KeyOffset) = (Cur \ 24)
    Cur = Cur Mod 24
    y = y -1
    Loop While y >= 0
    j = j -1
    winKeyOutput = Mid(Chars, Cur + 1, 1) & winKeyOutput
    Last = Cur
    Loop While j >= 0
    If (isWin8 = 1) Then
    keypart1 = Mid(winKeyOutput, 2, Last)
    insert = "N"
    winKeyOutput = Replace(winKeyOutput, keypart1, keypart1 & insert, 2, 1, 0)
    If Last = 0 Then winKeyOutput = insert & winKeyOutput
    End If
    a = Mid(winKeyOutput, 1, 5)
    b = Mid(winKeyOutput, 6, 5)
    c = Mid(winKeyOutput, 11, 5)
    d = Mid(winKeyOutput, 16, 5)
    e = Mid(winKeyOutput, 21, 5)
    ConvertToKey = a & "-" & b & "-" & c & "-" & d & "-" & e
End Function

Function CutSpaces (Input)
    Dim objRegEx
    Set objRegEx = CreateObject("VBScript.RegExp")
    objRegEx.Global = True
    objRegEx.Pattern = "\s+|\t+/ig"
    CutSpaces = objRegEx.Replace(Input, " ")
End Function
