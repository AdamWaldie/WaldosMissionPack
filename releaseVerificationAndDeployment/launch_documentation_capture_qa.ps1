param(
    [ValidateSet("economy-resources", "economy-resource-config", "economy-research", "economy-build", "economy-purchases", "economy-builder", "economy-drop-point", "safestart-countdown", "endex")]
    [string]$Case = "economy-resources",
    [switch]$CaptureScreenshot,
    [string]$ScreenshotPath = ".\.qa\documentation\capture.png",
    [switch]$CloseAfterCapture,
    [switch]$WithMods,
    [int]$ResolutionWidth = 2560,
    [int]$ResolutionHeight = 1440
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$armaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
$armaExe = Join-Path $armaRoot "arma3_x64.exe"
$missionRoot = Join-Path $armaRoot "Missions\WMP_Documentation_Capture.VR"
$profileRoot = Join-Path $repoRoot ".qa\documentation-capture\profile"
if (Get-Process arma3_x64 -ErrorAction SilentlyContinue) {
    throw "Close Arma before staging a documentation capture."
}
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) {
    $python = "C:\Users\AdamW\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
}
if (-not (Test-Path -LiteralPath $python)) { throw "Python is required." }
$modArgument = ""
if ($WithMods) {
    $modNames = @("@CBA_A3", "@ace", "@Zeus Enhanced", "@ACRE2")
    $mods = foreach ($name in $modNames) {
        $path = Join-Path (Join-Path $armaRoot "!Workshop") $name
        if (-not (Test-Path -LiteralPath $path)) { throw "Required capture mod is not installed: $name" }
        $path
    }
    $modArgument = '-mod="' + ($mods -join ';') + '"'
}
[System.IO.Directory]::CreateDirectory($profileRoot) | Out-Null

& $python (Join-Path $PSScriptRoot "build_documentation_capture_qa.py") --destination $missionRoot --case $Case
if ($LASTEXITCODE -ne 0) { throw "Documentation mission assembly failed." }
if (-not (Test-Path -LiteralPath (Join-Path $missionRoot "functionBootstrap.sqf"))) {
    throw "Documentation mission was not fully staged."
}

$qaRoot = "\Missions\WMP_Documentation_Capture.VR\"
$bootstrap = $qaRoot + "scriptedBootstrap.sqf"
$script = 'private _group=createGroup west;private _unit=_group createUnit ["B_Soldier_F",[0,0,0],[],0,"NONE"];selectPlayer _unit;Waldo_DocCapture_Root="' + $qaRoot + '";[] execVM "' + $bootstrap + '";'
$codes = ($script.ToCharArray() | ForEach-Object { [int]$_ }) -join ","
$arguments = @(
    "-noBattlEye", "-noSplash", "-skipIntro", "-world=empty", "-showScriptErrors", "-filePatching",
    "-window", "-noPause", "-x=$ResolutionWidth", "-y=$ResolutionHeight",
    "-windowWidth=$ResolutionWidth", "-windowHeight=$ResolutionHeight",
    "-profiles=$profileRoot", "-name=WMPDocumentationCapture",
    "-init=playScriptedMission[toString[86,82],compile(toString[$codes]),configNull,true]"
)
if ($WithMods) { $arguments += $modArgument }
$launchTime = Get-Date
$start = New-Object System.Diagnostics.ProcessStartInfo
$start.FileName = $armaExe
$start.UseShellExecute = $false
$start.Arguments = $arguments -join " "
$process = [System.Diagnostics.Process]::Start($start)
Write-Output "Launched documentation capture: $Case"

if ($CaptureScreenshot) {
    $deadline = (Get-Date).AddSeconds(75)
    $ready = $false
    while ((Get-Date) -lt $deadline -and -not $process.HasExited) {
        $rpt = Get-ChildItem (Join-Path $env:LOCALAPPDATA "Arma 3\arma3_x64_*.rpt") -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -ge $launchTime.AddSeconds(-2) } |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($rpt) {
            $tail = Get-Content -LiteralPath $rpt.FullName -Tail 120 -ErrorAction SilentlyContinue
            if ($tail -match "WMP DOC CAPTURE READY: case=$Case ready=true") { $ready = $true; break }
        }
        Start-Sleep -Milliseconds 250
        $process.Refresh()
    }
    if (-not $ready) { throw "Documentation state $Case did not become capture-ready." }
    Start-Sleep -Milliseconds 750
    & (Join-Path $PSScriptRoot "capture_interaction_ui.ps1") -OutputPath $ScreenshotPath
    if ($CloseAfterCapture -and -not $process.HasExited) {
        Stop-Process -Id $process.Id
        $process.WaitForExit(5000) | Out-Null
    }
}
