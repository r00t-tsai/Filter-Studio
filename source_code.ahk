#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; REFERENCE ONLY / SOURCE STUB
; Core display driver APIs, WMI hooks, and registry writers in this 
; Script have been intentionally neutered.
; ==============================================================================

MsgBox("This repository script is provided for structural and UI reference only.`n`nHardware interactions (Gamma Ramps, DDC/CI, WMI) are disabled in this open-source build.", "Filter Studio - Reference Build", "Icon!")

global SettingsFile := A_ScriptDir . "\FilterStudio.ini"
OnExit(OnAppExit)

global FilterColors := Map(
    "Red",           "FF0000",
    "Yellow",        "FFFF00",
    "Blue",          "0000FF",
    "Orange",        "FF7F00",
    "Green",         "00FF00",
    "Violet",        "8B00FF",
    "Red-Orange",    "FF4500",
    "Yellow-Orange", "FFBF00",
    "Yellow-Green",  "7FFF00",
    "Blue-Green",    "00FF7F",
    "Blue-Violet",   "4B0082",
    "Red-Violet",    "FF00FF"
)

global Presets := Map(
    "Eye Health",   {Bright: 85,  Strength: 55, Color: "Orange"},
    "Read",         {Bright: 90,  Strength: 30, Color: "Yellow-Orange"},
    "Game",         {Bright: 80,  Strength: 15, Color: "Blue"},
    "Movie",        {Bright: 55,  Strength: 45, Color: "Red-Orange"},
    "Custom",       {Bright: 100, Strength: 0,  Color: "Orange"},
    "Reset / Off",  {Bright: 100, Strength: 0,  Color: "Orange"}
)
global PresetOrder := ["Eye Health", "Read", "Game", "Movie", "Custom", "Reset / Off"]

global ColorList := [
    "Red", "Yellow", "Blue",
    "Orange", "Green", "Violet",
    "Red-Orange", "Yellow-Orange", "Yellow-Green", "Blue-Green", "Blue-Violet", "Red-Violet"
]

global BrightnessMethod    := "_MODE"
global DDCMonitorHandles   := []
global GammaMonitorDCs     := []
global SuppressSave        := false
global Schedule            := []
global lastAppliedScheduleKey := ""
global ApplyingPreset      := false
global CurrentPresetSource := ""
global lastAppliedRampKey  := ""
global StartupEnabled      := false
global Uses24HourClock     := true
global StartMinimized      := false
global RequirementsMet      := {brightness: true, colorFilter: true}

A_IconTip := "Filter Studio (Reference Only)"
Tray := A_TrayMenu
Tray.Delete()
Tray.Add("Show Filter Studio", (*) => mainGui.Show())
Tray.Add("Exit Filter Studio", (*) => ExitApp())
Tray.Default := "Show Filter Studio"

global mainGui := Gui("+AlwaysOnTop", "Filter Studio [Reference Build]")
mainGui.MarginX := 15
mainGui.MarginY := 15
mainGui.SetFont("s10 bold", "Segoe UI")
mainGui.Add("Text", "w330 xm", "Quick Presets:")
mainGui.SetFont("s9 norm", "Segoe UI")
btnEye    := mainGui.Add("Button", "w160 h35 xm y+8", "Eye Health")
btnRead   := mainGui.Add("Button", "w160 h35 x+10 yp", "Reading")
btnGame   := mainGui.Add("Button", "w160 h35 xm y+8", "Gaming")
btnMovie  := mainGui.Add("Button", "w160 h35 x+10 yp", "Movie")
btnCustom := mainGui.Add("Button", "w160 h35 xm y+8", "Custom")
btnReset  := mainGui.Add("Button", "w160 h35 x+10 yp", "Turn Off")

mainGui.SetFont("s10 bold", "Segoe UI")
mainGui.Add("Text", "w330 xm y+18", "Adjustments:")
mainGui.SetFont("s9 norm", "Segoe UI")
mainGui.Add("Text", "w330 xm y+8", "Screen Brightness:")
global sliderBright := mainGui.Add("Slider", "w330 xm y+2 Range10-100 ToolTip", 100)
mainGui.Add("Text", "w330 xm y+8", "Filter Color:")
global ddlColor := mainGui.Add("DropDownList", "w330 xm y+2 Choose4", ColorList)
mainGui.Add("Text", "w330 xm y+8", "Filter Strength:")
global sliderStrength := mainGui.Add("Slider", "w330 xm y+2 Range0-100 ToolTip", 50)

mainGui.SetFont("s10 bold", "Segoe UI")
mainGui.Add("Text", "w330 xm y+18", "Preferences:")
mainGui.SetFont("s9 norm", "Segoe UI")
global chkNotify := mainGui.Add("Checkbox", "w330 xm y+6 Checked1", "Show notifications")
global chkStartup := mainGui.Add("Checkbox", "w330 xm y+6", "Run automatically at Windows startup")

mainGui.SetFont("s10 bold", "Segoe UI")
mainGui.Add("Text", "w330 xm y+18", "Auto Schedule:")
mainGui.SetFont("s9 norm", "Segoe UI")
global chkAutoSchedule := mainGui.Add("Checkbox", "w330 xm y+6", "Automatic Switching")
global lvSchedule := mainGui.Add("ListView", "w330 h100 xm y+8", ["Time", "Preset"])
lvSchedule.ModifyCol(1, 115)
lvSchedule.ModifyCol(2, 205)
btnSchedAdd    := mainGui.Add("Button", "w105 y+6 xm", "Add...")
btnSchedEdit   := mainGui.Add("Button", "w105 x+7 yp", "Edit...")
btnSchedRemove := mainGui.Add("Button", "w105 x+7 yp", "Remove")

global txtStatus := mainGui.Add("Text", "w330 xm y+14 cRed", "")

btnEye.OnEvent("Click", (*) => ApplyPreset("Eye Health"))
btnRead.OnEvent("Click", (*) => ApplyPreset("Read"))
btnGame.OnEvent("Click", (*) => ApplyPreset("Game"))
btnMovie.OnEvent("Click", (*) => ApplyPreset("Movie"))
btnCustom.OnEvent("Click", (*) => ApplyPreset("Custom"))
btnReset.OnEvent("Click", (*) => ApplyPreset("Reset / Off"))

sliderBright.OnEvent("Change", (*) => OnAdjustmentChanged())
sliderStrength.OnEvent("Change", (*) => OnAdjustmentChanged())
ddlColor.OnEvent("Change", (*) => OnAdjustmentChanged())
chkNotify.OnEvent("Click", (*) => SaveSettings())
chkAutoSchedule.OnEvent("Click", (*) => OnAutoScheduleToggled())
chkStartup.OnEvent("Click", (*) => OnStartupToggled())
btnSchedAdd.OnEvent("Click", (*) => OpenScheduleEditor(false))
btnSchedEdit.OnEvent("Click", (*) => OpenScheduleEditor(true))
btnSchedRemove.OnEvent("Click", (*) => RemoveScheduleEntry())

mainGui.OnEvent("Close", MinimizeToTray)

MinimizeToTray(*) {
    mainGui.Hide()
    if (chkNotify.Value = 1) {
        TrayTip("Filter Studio is minimized in the system tray.`nPress Ctrl + Shift + F to reopen.", "Filter Studio", 1)
    }
}

^+f:: {
    if WinExist("Filter Studio")
        mainGui.Hide()
    else
        mainGui.Show()
}

mainGui.Show("Center")


; STUBBED HARDWARE & DISPLAY FUNCTIONS


GetMonitorDCs() {
    ;  returning no display contexts
    return []
}

BuildGammaRamp(colorName, strengthVal) {
    ; Empty buffer stub
    return Buffer(1536, 0)
}

ApplyGammaRamp(buf) {
    ; Disabled GDI Call: DllCall("gdi32\SetDeviceGammaRamp", ...)
    ToolTip(": Gamma Ramp applied (Hardware calls disabled).")
    SetTimer(() => ToolTip(), -1500)
}

RestoreLinearGamma() {
    ;  gamma reset
    return
}

DetectBrightnessMethod() {
    global BrightnessMethod := "Disabled"
}

GetDDCMonitorHandles() {
    return []
}

SetSystemBrightness(level) {
    ; Disabled WMI and DDC/CI commands
    ToolTip(": Set brightness to " . level . "% (Hardware calls disabled).")
    SetTimer(() => ToolTip(), -1500)
}

SetStartupRegistry(enable) {
    ; Disabled Registry modification
    ToolTip(": Registry startup change skipped.")
    SetTimer(() => ToolTip(), -1500)
}


; LOGIC AND GUI HELPERS


ApplyPreset(name) {
    global Presets, sliderBright, sliderStrength, ddlColor, ApplyingPreset, CurrentPresetSource
    p := Presets[name]
    ApplyingPreset := true
    sliderBright.Value   := p.Bright
    sliderStrength.Value := p.Strength
    ddlColor.Text        := p.Color
    ApplyingPreset := false
    CurrentPresetSource := name
    CommitDisplayUpdate()
}

OnAdjustmentChanged() {
    global ApplyingPreset, CurrentPresetSource
    if (!ApplyingPreset) {
        SaveAsCustomPreset()
        CurrentPresetSource := "Custom"
    }
    RequestDisplayUpdate()
}

SaveAsCustomPreset() {
    global Presets, sliderBright, sliderStrength, ddlColor
    Presets["Custom"] := {Bright: sliderBright.Value, Strength: sliderStrength.Value, Color: ddlColor.Text}
}

RequestDisplayUpdate() {
    SetTimer(CommitDisplayUpdate, -120)
}

CommitDisplayUpdate() {
    global sliderBright, sliderStrength, ddlColor, lastAppliedRampKey
    brightVal   := sliderBright.Value
    strengthVal := sliderStrength.Value
    colorName   := ddlColor.Text

    key := brightVal . "|" . strengthVal . "|" . colorName
    if (key != lastAppliedRampKey) {
        lastAppliedRampKey := key
        SetSystemBrightness(brightVal)
        ramp := BuildGammaRamp(colorName, strengthVal)
        ApplyGammaRamp(ramp)
    }
}

OnAutoScheduleToggled() {
    SaveSettings()
}

OnStartupToggled() {
    global chkStartup, StartupEnabled
    StartupEnabled := chkStartup.Value = 1
    SetStartupRegistry(StartupEnabled)
}

DetectSystemTimeFormat() {
    return true
}

OpenScheduleEditor(editMode) {
    global lvSchedule, Schedule, mainGui, PresetOrder, Uses24HourClock

    editIndex := 0
    if editMode {
        editIndex := lvSchedule.GetNext()
        if !editIndex {
            Flash("Select a schedule entry to edit first")
            return
        }
    }

    ed := Gui("+Owner" mainGui.Hwnd " +AlwaysOnTop", editMode ? "Edit Schedule Entry" : "Add Schedule Entry")
    ed.SetFont("s9", "Segoe UI")

    ed.Add("Text", "xm y12", "Time (24-hour):")
    edHour := ed.Add("Edit", "x+8 yp-3 w45 Number Center", "")
    ed.Add("Text", "x+4 yp3", ":")
    edMin  := ed.Add("Edit", "x+4 yp-3 w45 Number Center", "")
    ed.Add("Text", "xm y+4", "Hour 0-23, minute 0-59")
    ddlAmPm := ""

    ed.Add("Text", "xm y+15", "Preset:")
    ddlPreset := ed.Add("DropDownList", "x+8 yp-3 w150", PresetOrder)

    if editMode {
        entry := Schedule[editIndex]
        edHour.Text := entry.hour
        edMin.Text     := entry.min
        ddlPreset.Text := entry.preset
    } else {
        edHour.Text := A_Hour
        edMin.Text := A_Min
        ddlPreset.Choose(1)
    }

    btnOK     := ed.Add("Button", "xm y+20 w110 Default", "OK")
    btnCancel := ed.Add("Button", "x+10 yp w110", "Cancel")

    btnOK.OnEvent("Click", (*) => SaveScheduleEntry(ed, edHour, edMin, ddlAmPm, ddlPreset, editMode, editIndex))
    btnCancel.OnEvent("Click", (*) => ed.Destroy())
    ed.OnEvent("Close", (*) => ed.Destroy())
    ed.Show("w280 h170")
}

SaveScheduleEntry(ed, edHour, edMin, ddlAmPm, ddlPreset, editMode, editIndex) {
    global Schedule

    hRaw := Trim(edHour.Text)
    mRaw := Trim(edMin.Text)
    if (hRaw = "" || mRaw = "" || !IsInteger(hRaw) || !IsInteger(mRaw)) {
        Flash("Enter a valid hour and minute")
        return
    }

    h := Integer(hRaw)
    m := Integer(mRaw)
    if (m < 0 || m > 59 || h < 0 || h > 23) {
        Flash("Invalid time format")
        return
    }

    p := ddlPreset.Text
    if (p = "") {
        Flash("Choose a preset")
        return
    }

    entry := {hour: h, min: m, preset: p}
    if editMode
        Schedule[editIndex] := entry
    else
        Schedule.Push(entry)

    RefreshScheduleListView()
    ed.Destroy()
}

RemoveScheduleEntry() {
    global lvSchedule, Schedule
    idx := lvSchedule.GetNext()
    if !idx {
        Flash("Select a schedule entry to remove")
        return
    }
    Schedule.RemoveAt(idx)
    RefreshScheduleListView()
}

RefreshScheduleListView() {
    global lvSchedule, Schedule
    lvSchedule.Delete()
    for e in Schedule
        lvSchedule.Add(, Format("{:02}:{:02}", e.hour, e.min), e.preset)
}

SaveSettings() {
    ;  INI writes omitted
}

LoadSettings() {
    ;  INI reads omitted
}

OnAppExit(*) {
    ; Cleanup stub
}

Flash(msg) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -2000)
}
