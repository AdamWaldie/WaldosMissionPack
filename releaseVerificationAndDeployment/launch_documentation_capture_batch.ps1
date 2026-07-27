param(
    [string[]]$Cases = @(
        "economy-resources", "economy-resource-config", "economy-research", "economy-build", "economy-purchases", "economy-builder", "economy-drop-point",
        "interaction-wirecut-briefing", "interaction-wirecut-active",
        "interaction-minesweeper-briefing", "interaction-minesweeper-active",
        "interaction-keypad-briefing", "interaction-keypad-active",
        "interaction-lockpick-briefing", "interaction-lockpick-active",
        "interaction-circuit-briefing", "interaction-circuit-active",
        "interaction-repair-briefing", "interaction-repair-active",
        "interaction-radiotune-briefing", "interaction-radiotune-active",
        "interaction-pressure-briefing", "interaction-pressure-active",
        "interaction-sequence-briefing", "interaction-sequence-active",
        "interaction-commandinput-briefing", "interaction-commandinput-active",
        "safestart-countdown", "endex"
    ),
    [string]$OutputDirectory = ".\.qa\documentation-gallery",
    [int]$ResolutionWidth = 2560,
    [int]$ResolutionHeight = 1440
)
$ErrorActionPreference = "Stop"
trap {
    Write-Output "WMP DOC CAPTURE CONTROLLER ERROR: $($_.Exception.Message)"
    Write-Output $_.ScriptStackTrace
    exit 1
}
$repoRoot = Split-Path -Parent $PSScriptRoot
$armaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
$armaExe = Join-Path $armaRoot "arma3_x64.exe"
$missionRoot = Join-Path $armaRoot "Missions\WMP_Documentation_Capture.VR"
$profileRoot = Join-Path $repoRoot ".qa\documentation-capture\profile"
if (Get-Process arma3_x64 -ErrorAction SilentlyContinue) { throw "Close Arma before staging the capture batch." }
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) { $python = "C:\Users\AdamW\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" }
$buildArgs = @((Join-Path $PSScriptRoot "build_documentation_capture_qa.py"), "--destination", $missionRoot, "--case", $Cases[0], "--cases") + $Cases
& $python $buildArgs
if ($LASTEXITCODE -ne 0) { throw "Documentation batch assembly failed." }

$modNames = @("@CBA_A3", "@ace", "@Zeus Enhanced", "@ACRE2")
$mods = foreach ($name in $modNames) {
    $path = Join-Path (Join-Path $armaRoot "!Workshop") $name
    if (-not (Test-Path -LiteralPath $path)) { throw "Required capture mod is not installed: $name" }
    $path
}
$modArgument = '-mod="' + ($mods -join ';') + '"'
[System.IO.Directory]::CreateDirectory($profileRoot) | Out-Null
$output = [System.IO.Path]::GetFullPath($OutputDirectory)
[System.IO.Directory]::CreateDirectory($output) | Out-Null

$qaRoot = "\Missions\WMP_Documentation_Capture.VR\"
$bootstrap = $qaRoot + "scriptedBootstrap.sqf"
$script = 'private _group=createGroup west;private _unit=_group createUnit ["B_Soldier_F",[0,0,0],[],0,"NONE"];selectPlayer _unit;Waldo_DocCapture_Root="' + $qaRoot + '";[] execVM "' + $bootstrap + '";'
$codes = ($script.ToCharArray() | ForEach-Object { [int]$_ }) -join ","
$arguments = @(
    "-noBattlEye", "-noSplash", "-skipIntro", "-world=empty", "-showScriptErrors", "-filePatching", "-window", "-noPause",
    "-x=$ResolutionWidth", "-y=$ResolutionHeight", "-windowWidth=$ResolutionWidth", "-windowHeight=$ResolutionHeight",
    "-profiles=$profileRoot", "-name=WMPDocumentationCapture", $modArgument,
    "-init=playScriptedMission[toString[86,82],compile(toString[$codes]),configNull,true]"
)
$launchTime = Get-Date
$start = New-Object System.Diagnostics.ProcessStartInfo
$start.FileName = $armaExe
$start.UseShellExecute = $false
$start.Arguments = $arguments -join " "
$launchProcess = [System.Diagnostics.Process]::Start($start)
$seen = @{}
$failed = @{}
$captureErrors = @{}
$deadline = (Get-Date).AddSeconds(300)
while ((Get-Date) -lt $deadline -and $seen.Count -lt $Cases.Count) {
    // Steam may replace the process returned by Start with the real game
    // process. Follow the current Arma instance instead of treating that
    // hand-off as the end of the capture run.
    $armaProcess = Get-Process arma3_x64 -ErrorAction SilentlyContinue |
        Sort-Object Id -Descending | Select-Object -First 1
    if (-not $armaProcess -and (Get-Date) -gt $launchTime.AddSeconds(45)) { break }
    $rpt = Get-ChildItem $profileRoot -Filter "arma3_x64_*.rpt" -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -ge $launchTime.AddSeconds(-2) } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($rpt) {
        $tail = Get-Content -LiteralPath $rpt.FullName -Tail 220 -ErrorAction SilentlyContinue
        $tailText = $tail -join "`n"
        foreach ($case in $Cases) {
            if (-not $seen.ContainsKey($case) -and ($tailText -match "WMP DOC CAPTURE READY: case=$case ready=(true|false)")) {
                $caseReady = $Matches[1] -eq "true"
                $seen[$case] = $true
                if (-not $caseReady) { $failed[$case] = $true }
                try {
                    Write-Output "Capturing $case (runtime validation: $caseReady)"
                    & (Join-Path $PSScriptRoot "capture_interaction_ui.ps1") -OutputPath (Join-Path $output "$case.png")
                }
                catch {
                    $captureErrors[$case] = $_.Exception.Message
                    Write-Warning "Capture failed for ${case}: $($_.Exception.Message)"
                }
            }
        }
    }
    Start-Sleep -Milliseconds 150
}
$armaProcess = Get-Process arma3_x64 -ErrorAction SilentlyContinue |
    Sort-Object Id -Descending | Select-Object -First 1
if ($armaProcess) {
    Stop-Process -Id $armaProcess.Id
    $armaProcess | Wait-Process -Timeout 5 -ErrorAction SilentlyContinue
}
$missing = $Cases | Where-Object { -not $seen.ContainsKey($_) }
if ($missing.Count -gt 0) { throw "Capture batch missed: $($missing -join ', ')" }
if ($captureErrors.Count -gt 0) {
    $details = $captureErrors.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }
    throw "Capture failures: $($details -join '; ')"
}
if ($failed.Count -gt 0) { throw "Capture batch recorded runtime findings: $($failed.Keys -join ', ')" }
Write-Output "Captured $($seen.Count) documentation states in one Arma session: $output"
