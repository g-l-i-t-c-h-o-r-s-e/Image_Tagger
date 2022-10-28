;AHk BASED Image Dataset Tagging Tool
;Pandela 2022
SetWorkingDir, A_ScriptDir
SetBatchLines, -1 ; For speed in general
#Include z_Gdip_All.ahk
DDB_Path := "D:\DeepDanbooru\DeepDanbooru\ayylmao" ;Set DeepDanbooru project folder here
extensions := "png,jpg,jpeg" ;image extensions to load

;dont touch
array := []
CurrentImage := 1
PreviousImage := 0

;Start Tag Autocompletion script
Autocomplete := A_ScriptDir "./Autocomplete-master/Autocomplete.ahk"
run, %Autocomplete%

;Grab each image filepath and add it to the array.
IniRead,LePath,lastFolder.ini,Folder ;Get location of last used folder
FileSelectFolder,LePath,%LePath%,3 ;select folder containing your images
Loop, Files,%LePath%\*.*
{
	if A_LoopFileExt in %extensions% 
	{
		array.Push(A_LoopFileFullPath)
	}
}
ArrayCount := array.Length() ;get length of array
ImageCount := (ArrayCount)



;Rewrite last used folder config
FileDelete,lastFolder.ini
IniWrite,%LePath%,lastFolder.ini,Folder

;create bitmap for gui
pToken := Gdip_StartUp()
pBitmap := Gdip_CreateBitmapFromFile(array[1])
hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
Gdip_GetImageDimensions(pBitmap, w, h)

;resize img preview in gui accordingly to prevent bugs
w2 := (w / 2 - 30)
h2 := (h / 2 - 30)

if (w2 > 1000) {
	w2 := (w2 / 2 - 30)
	h2 := (h2 / 2 - 30)
}

if (h2 > 1000) {
	h2 := (h2 / 2 - 30)
	w2 := (w2 / 2 - 30)	
}


SplitPath,% array[CurrentImage],,dir,ext2,name
TagFile := dir "\" name . ".txt"
FileRead,Tags, %TagFile%

FileGetSize, FilesizeKb, % array[CurrentImage]
FileGetSize, FilesizeMb, % array[CurrentImage], M

Gui, Add, Pic, w%w2% h%h2% x10 vPic +Border gOpenImg, % "HBITMAP:*" hBitmap
Gui, Add, Button, x163 y700 w147 h40 vButton +Border gNextImage, Next Image
Gui, Add, Button, x10 y700 w150 h40 gPreviously +Border, Previous Image
Gui, Add, Button, w300 h40 x10 vButton2 +Border gSaveTags, Save Tags
Gui, Add, Edit, w600 h200 x10 vEdit +Border, %Tags%
Gui, Add, Edit, x321 y700 w180 h86 vEdit2 -Border -VScroll +Disabled
Gui, Add, Button, x510 y700 w100 h86 gDeepDanbooru, DeepDanbooru

ImageCount := (ImageCount - 1)
GuiControl,,Edit2, % name "." ext2 "`nWidth: " w "`nHeight: " h "`nFilesize: " FilesizeKb " Kbs (" FilesizeMb " Mbs)`n`nImage [" CurrentImage "] of [" ArrayCount "] (" ImageCount " Left)"
Gui, Show, w1500 h1030
Return


NextImage:
if (CurrentImage = ArrayCount) && (PreviousImage = 0) { ;Reset Image array back to first image at the end of array
	global CurrentImage := 0
	global ImageCount := (ArrayCount + 1)
}

;Iterate Images
if (PreviousImage = 1) {
     global CurrentImage -= 1
}

if (PreviousImage = 0) {
	global CurrentImage += 1
}


Gdip_DisposeImage(pBitmap)
pBitmap := Gdip_CreateBitmapFromFile(array[CurrentImage])
hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
Gdip_GetImageDimensions(pBitmap, w, h)

;resize img preview in gui accordingly to prevent bugs
w2 := (w / 2 - 30)
h2 := (h / 2 - 30)

if (w2 > 1000) {
	w2 := (w2 / 3)
	h2 := (h2 / 3)	
}

if (h2 > 700) {
	h2 := (h2 / 2 + 50)
	w2 := (w2 / 2 + 50)	
}

if (h2 > 1000) {
	h2 := (h2 / 3)
	w2 := (w2 / 3)	
}

if (h2 > 2500) {
	h2 := (h2 / 2)
	w2 := (w2 / 2)	
}

;update UI with image and tags
SplitPath,% array[CurrentImage],,dir,ext2,name
TagFile := dir "\" name . ".txt"
GuiControl, Move, Pic, % "w" w2 " h" h2
GuiControl, , Pic, % "HBITMAP:*" hBitmap
FileRead,Tags, %TagFile%

FileGetSize, FilesizeKb, % array[CurrentImage]
FileGetSize, FilesizeMb, % array[CurrentImage], M
GuiControl,,Edit, % Tags

if (PreviousImage = 0) {
ImageCount := (ImageCount - 1)
}

if (PreviousImage = 1) {
	ImageCount := (ArrayCount - CurrentImage)
}

if (ImageCount = ArrayCount) {
	ImageCount := (ImageCount - 1)
}
	
GuiControl,,Edit2, % name "." ext2 "`nWidth: " w "`nHeight: " h "`nFilesize: " FilesizeKb " Kbs (" FilesizeMb " Mbs)`n`nImage [" CurrentImage "] of [" ArrayCount "] (" ImageCount " Left)"
Return

Previously:
if (CurrentImage = ArrayCount - ArrayCount + 1) { ;Reset Image array back to first image at the end of array
	global CurrentImage := ArrayCount + 1
	;global ImageCount := CurrentImage
}

PreviousImage := 1
gosub, NextImage
PreviousImage := 0
return

OpenImg:
Run, % array[CurrentImage]
return


;save current tags to variable, delete old tags and replace with new
SaveTags:
Gui, Submit, NoHide
FileDelete, %TagFile%
FileAppend, %Edit%, %TagFile%
Return


DeepDanbooru:
FileCopy,% array[CurrentImage],% Temp
SplitPath,% array[CurrentImage],,,ext,TempPath
TempPath := Temp "\" TempPath "." ext
DDB := "deepdanbooru evaluate " TempPath " --project-path " DDB_Path " --save-txt"
Runwait, %DDB%

;Save DeepDanbooru tags to variable and delete temp files
FileDelete, %TempPath%
TempPath := StrReplace(TempPath,"." ext,".txt")
FileRead, DeepDanbooru_Tags, %TempPath%
FileDelete, %TempPath%

;Get current tags and append DeepDanbooru tags
Gui,Submit,Nohide
NewTags := Edit . DeepDanbooru_Tags
NewTags := RemoveDuplicate(NewTags)
GuiControl,,Edit, % NewTags
return

;esc key closes gui
GuiClose:
GuiEscape:
CloseScript("Autocomplete.ahk")
sleep, 100
ExitApp


;www.autohotkey.com/board/topic/91682-how-to-remove-duplicated-lines-with-regex/?p=588529
RemoveDuplicate(str, delim:=",", cs:=false) {
	_ := cs ? ComObjCreate("Scripting.Dictionary") : []
	Loop, Parse, str, % delim
		alf := A_LoopField
		, out .= cs ? (_.Exists(alf) ? "" : (alf . delim, _.Add(alf, 1)))
		            : (_[alf] ? "" : (alf . delim, _[alf] := 1))
	return RTrim(out, delim)
}



;https://www.autohotkey.com/boards/viewtopic.php?t=75425#p326361
CloseScript(scriptName, kill := false)  {
	static WM_COMMAND := 0x111, ID_FILE_TERMINATESCRIPT := 65405
	
	dhw_prev := A_DetectHiddenWindows
	tmm_prev := A_TitleMatchMode
	
	DetectHiddenWindows, On
	SetTitleMatchMode, 2
	WinExist(scriptName)
	if !kill
		PostMessage, WM_COMMAND, ID_FILE_TERMINATESCRIPT
	else  {
		WinGet, PID, PID
		Process, Close, % PID
	}
	DetectHiddenWindows, % dhw_prev
	SetTitleMatchMode, % tmm_prev
}