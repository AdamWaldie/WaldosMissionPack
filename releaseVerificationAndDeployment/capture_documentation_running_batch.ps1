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
    [string]$OutputDirectory = ".\.qa\documentation-gallery"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$profileRoot = Join-Path $repoRoot ".qa\documentation-capture\profile"
$output = [System.IO.Path]::GetFullPath($OutputDirectory)
[System.IO.Directory]::CreateDirectory($output) | Out-Null
if (-not (Get-Process arma3_x64 -ErrorAction SilentlyContinue)) {
    throw "No running Arma documentation batch was found."
}

$rpt = Get-ChildItem $profileRoot -Filter "arma3_x64_*.rpt" -ErrorAction Stop |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
$seen = @{}
$failed = @{}
$captureErrors = @{}
$deadline = (Get-Date).AddSeconds(300)
while ((Get-Date) -lt $deadline -and $seen.Count -lt $Cases.Count) {
    $tail = Get-Content -LiteralPath $rpt.FullName -Tail 260 -ErrorAction SilentlyContinue
    $tailText = $tail -join "`n"
    foreach ($case in $Cases) {
        if (-not $seen.ContainsKey($case) -and ($tailText -match "WMP DOC CAPTURE READY: case=$case ready=(true|false)")) {
            $caseReady = $Matches[1] -eq "true"
            $seen[$case] = $true
            if (-not $caseReady) {$failed[$case] = $true}
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
    Start-Sleep -Milliseconds 120
}

$armaProcess = Get-Process arma3_x64 -ErrorAction SilentlyContinue | Sort-Object Id -Descending | Select-Object -First 1
if ($armaProcess) {
    Stop-Process -Id $armaProcess.Id
    $armaProcess | Wait-Process -Timeout 5 -ErrorAction SilentlyContinue
}
$missing = $Cases | Where-Object {-not $seen.ContainsKey($_)}
if ($missing.Count -gt 0) {throw "Capture batch missed: $($missing -join ', ')"}
if ($captureErrors.Count -gt 0) {
    $details = $captureErrors.GetEnumerator() | ForEach-Object {"$($_.Key): $($_.Value)"}
    throw "Capture failures: $($details -join '; ')"
}
if ($failed.Count -gt 0) {throw "Capture batch recorded runtime findings: $($failed.Keys -join ', ')"}
Write-Output "Captured $($seen.Count) documentation states in one Arma session: $output"
