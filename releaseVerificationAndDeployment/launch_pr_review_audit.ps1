param(
    [ValidateSet("all", "core", "economy", "ew", "party", "interactions")]
    [string]$Suite = "all",
    [ValidateSet("Manual", "Automated")]
    [string]$Mode = "Manual",
    [int]$Port = 24132,
    [int]$ResolutionWidth = 2560,
    [int]$ResolutionHeight = 1440,
    [string]$PythonExecutable = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$armaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
$armaExe = Join-Path $armaRoot "arma3_x64.exe"
$missionRoot = Join-Path $armaRoot "MPMissions\WMP_PR_Review_Audit.VR"
$profileRoot = Join-Path $repoRoot ".qa\pr-review-audit\hosted-profile"

if (Get-Process arma3_x64 -ErrorAction SilentlyContinue) {
    throw "Close Arma before staging the PR review audit."
}
if ([string]::IsNullOrWhiteSpace($PythonExecutable)) {
    $PythonExecutable = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
}
if (-not (Test-Path -LiteralPath $PythonExecutable)) { throw "Python was not found." }

& $PythonExecutable (Join-Path $PSScriptRoot "build_pr_review_audit.py") --destination $missionRoot --suite $Suite --mode $Mode.ToLowerInvariant()
if ($LASTEXITCODE -ne 0) { throw "PR review audit staging failed." }

$modNames = @("@CBA_A3", "@ace", "@Zeus Enhanced", "@ACRE2")
$mods = foreach ($name in $modNames) {
    $path = Join-Path (Join-Path $armaRoot "!Workshop") $name
    if (-not (Test-Path -LiteralPath $path)) { throw "Required audit mod is not installed: $name" }
    $path
}
$modArgument = '-mod="' + ($mods -join ';') + '"'
New-Item -ItemType Directory -Path $profileRoot -Force | Out-Null
$arguments = @(
    "-noBattlEye", "-showScriptErrors", "-window",
    "-x=$ResolutionWidth", "-y=$ResolutionHeight", "-port=$Port",
    "-profiles=$profileRoot", "-name=WMPAuditHost", "-host", $modArgument
)
Start-Process -FilePath $armaExe -ArgumentList $arguments
Write-Output "Staged the full WMP development pack and launched WMP PR REVIEW AUDIT in $Mode mode. Select Virtual Reality, WMP PR REVIEW AUDIT, Play, a slot, then OK."
