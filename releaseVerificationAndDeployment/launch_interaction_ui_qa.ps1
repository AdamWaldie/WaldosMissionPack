param(
    [ValidateSet("Interactive", "Active", "Automated", "Dialogue")]
    [string]$Mode = "Interactive",
    [ValidateSet("wirecut", "minesweeper", "keypad", "lockpick", "circuit", "repair", "radiotune", "pressure", "sequence", "commandinput")]
    [string]$Challenge = "wirecut",
    [ValidateSet("easy", "standard", "hard", "expert")]
    [string]$Difficulty = "standard",
    [switch]$AllDifficulties,
    [switch]$CaptureScreenshot,
    [string]$ScreenshotPath = ".\.qa\interaction-ui.png",
    [switch]$CloseAfterCapture,
    [int]$ResolutionWidth = 3840,
    [int]$ResolutionHeight = 2160
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$armaKey = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3"
$armaRoot = $armaKey.main
$armaExe = Join-Path $armaRoot "arma3_x64.exe"
if (-not (Test-Path -LiteralPath $armaExe)) {
    throw "Arma 3 executable not found at $armaExe"
}

$missionContainer = "Missions"
$missionRoot = Join-Path $armaRoot "$missionContainer\WMP_Interaction_UI_QA.VR"
$python = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $python) {
    $bundledPython = "C:\Users\AdamW\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
    if (-not (Test-Path -LiteralPath $bundledPython)) {
        throw "Python is required to assemble the disposable QA mission."
    }
    $pythonPath = $bundledPython
} else {
    $pythonPath = $python.Source
}
$autoTestConfig = Join-Path $repoRoot ".qa\WMP_Interaction_UI_QA.cfg"
$buildArguments = @(
    (Join-Path $PSScriptRoot "build_interaction_ui_qa.py"),
    "--destination", $missionRoot,
    "--mode", $Mode.ToLowerInvariant(),
    "--challenge", $Challenge,
    "--difficulty", $Difficulty,
    "--autotest-config", $autoTestConfig
)
if ($AllDifficulties) {
    $buildArguments += "--all-difficulties"
}
& $pythonPath $buildArguments
if ($LASTEXITCODE -ne 0) {
    throw "QA mission assembly failed."
}

$arguments = @(
    "-noBattlEye",
    "-noSplash",
    "-skipIntro",
    "-world=empty",
    "-showScriptErrors",
    "-filePatching",
    "-window",
    "-x=$ResolutionWidth",
    "-y=$ResolutionHeight",
    "-windowWidth=$ResolutionWidth",
    "-windowHeight=$ResolutionHeight",
    "-noPause"
)
# Encode the scripted mission body so Windows cannot strip SQF string quotes.
$qaRoot = "\Missions\WMP_Interaction_UI_QA.VR\"
$bootstrap = $qaRoot + "scriptedBootstrap.sqf"
$scriptedCode = 'private _group=createGroup west;private _unit=_group createUnit ["B_Soldier_F",[0,0,0],[],0,"NONE"];selectPlayer _unit;Waldo_MG_QA_Root="' + $qaRoot + '";[] execVM "' + $bootstrap + '";'
$scriptedCodes = ($scriptedCode.ToCharArray() | ForEach-Object { [int]$_ }) -join ","
$arguments += "-init=playScriptedMission[toString[86,82],compile(toString[$scriptedCodes]),configNull,true]"
$launchTime = Get-Date
$processStart = New-Object System.Diagnostics.ProcessStartInfo
$processStart.FileName = $armaExe
$processStart.UseShellExecute = $false
$processStart.Arguments = $arguments -join " "
$process = [System.Diagnostics.Process]::Start($processStart)
Write-Output "Launched $Mode interaction-equipment QA mission from $missionRoot"

if ($CaptureScreenshot) {
    $deadline = (Get-Date).AddSeconds(45)
    $ready = $false
    while ((Get-Date) -lt $deadline -and -not $process.HasExited) {
        $rpt = Get-ChildItem (Join-Path $env:LOCALAPPDATA "Arma 3\arma3_x64_*.rpt") -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -ge $launchTime.AddSeconds(-2) } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($null -ne $rpt) {
            $tail = Get-Content -LiteralPath $rpt.FullName -Tail 80 -ErrorAction SilentlyContinue
            if ($tail -match "WMP INTERACTION UI QA GEOMETRY:|WMP DIALOGUE UI QA GEOMETRY:") {
                $ready = $true
                break
            }
        }
        Start-Sleep -Milliseconds 250
        $process.Refresh()
    }
    if (-not $ready) {
        throw "Arma QA display did not become capture-ready within 45 seconds."
    }
    Start-Sleep -Milliseconds 500
    & (Join-Path $PSScriptRoot "capture_interaction_ui.ps1") -OutputPath $ScreenshotPath
    if ($CloseAfterCapture -and -not $process.HasExited) {
        Stop-Process -Id $process.Id
        $process.WaitForExit(5000) | Out-Null
    }
}
