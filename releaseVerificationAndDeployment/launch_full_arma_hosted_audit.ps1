param(
    [ValidateSet("all", "core", "economy", "ew", "party", "interactions")]
    [string]$Suite = "all",
    [ValidateSet("core", "acre", "tfar")]
    [string]$ModProfile = "acre",
    [ValidateSet("Manual", "Automated")]
    [string]$Mode = "Manual",
    [int]$Port = 24132,
    [ValidateRange(1280, 3840)]
    [int]$ResolutionWidth = 2560,
    [ValidateRange(720, 2160)]
    [int]$ResolutionHeight = 1440,
    [string]$PythonExecutable = ""
)

$ErrorActionPreference = "Stop"
$armaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
$armaExe = Join-Path $armaRoot "arma3_x64.exe"
$missionRoot = Join-Path $armaRoot "MPMissions\WMP_Full_Arma_Audit.VR"
$repoRoot = Split-Path -Parent $PSScriptRoot
$profileRoot = Join-Path $repoRoot ".qa\full-arma-audit\hosted-profile"

if (Get-Process arma3_x64 -ErrorAction SilentlyContinue) {
    throw "Close Arma 3 before staging an audit mission. While the game is open, only monitor the RPT and record findings."
}

foreach ($auditName in ("WMP_Full_Arma_Audit.VR", "WMP_FULL_PACK_AUDIT.VR", "WMP_FPA.VR")) {
    $editorRoot = Join-Path $armaRoot ("Missions\" + $auditName)
    if (Test-Path -LiteralPath $editorRoot) {
        Remove-Item -LiteralPath $editorRoot -Recurse -Force
    }
    if ($auditName -ne "WMP_Full_Arma_Audit.VR") {
        $legacyMultiplayerRoot = Join-Path $armaRoot ("MPMissions\" + $auditName)
        if (Test-Path -LiteralPath $legacyMultiplayerRoot) {
            Remove-Item -LiteralPath $legacyMultiplayerRoot -Recurse -Force
        }
    }
    $savedMission = Join-Path $profileRoot ("Users\WMPAuditHost\Saved\mpmissions\" + $auditName)
    if (Test-Path -LiteralPath $savedMission) {
        Remove-Item -LiteralPath $savedMission -Recurse -Force
    }
}

if ([string]::IsNullOrWhiteSpace($PythonExecutable)) {
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($null -ne $pythonCommand) {
        $PythonExecutable = $pythonCommand.Source
    }
    else {
        $bundledPython = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
        if (Test-Path -LiteralPath $bundledPython) { $PythonExecutable = $bundledPython }
    }
}
if ([string]::IsNullOrWhiteSpace($PythonExecutable) -or -not (Test-Path -LiteralPath $PythonExecutable)) {
    throw "Python was not found. Install Python, add it to PATH, or pass -PythonExecutable."
}

if ($Suite -in @("all", "ew") -and $ModProfile -eq "core") {
    throw "Suite '$Suite' requires -ModProfile acre or tfar so radio integration is actually tested."
}

& $PythonExecutable (Join-Path $PSScriptRoot "build_full_arma_audit.py") --destination $missionRoot --suite $Suite --mod-profile $ModProfile --mode $Mode.ToLowerInvariant()
if ($LASTEXITCODE -ne 0) { throw "Feature-range mission assembly failed." }

$modNames = switch ($ModProfile) {
    "core" { @("@CBA_A3", "@ace", "@Zeus Enhanced") }
    "acre" { @("@CBA_A3", "@ace", "@Zeus Enhanced", "@ACRE2") }
    "tfar" { @("@CBA_A3", "@ace", "@Zeus Enhanced", "@Task Force Arrowhead Radio (BETA!!!)") }
}
$mods = @()
foreach ($name in $modNames) {
    $path = Join-Path (Join-Path $armaRoot "!Workshop") $name
    if (-not (Test-Path -LiteralPath $path)) { throw "Required audit mod is not installed: $name" }
    $mods += $path
}
$modArgument = '-mod="' + ($mods -join ';') + '"'

New-Item -ItemType Directory -Path $profileRoot -Force | Out-Null
$arguments = @(
    "-noBattlEye",
    "-showScriptErrors",
    "-window",
    "-x=$ResolutionWidth",
    "-y=$ResolutionHeight",
    "-port=$Port",
    "-profiles=$profileRoot",
    "-name=WMPAuditHost",
    "-host",
    $modArgument
)

Start-Process -FilePath $armaExe -ArgumentList $arguments
Write-Output "Staged WMP_Full_Arma_Audit.VR in $Mode mode and opened a hosted multiplayer server. Select Virtual Reality > WMP FULL PACK AUDIT > Play, choose a slot, then press OK."
