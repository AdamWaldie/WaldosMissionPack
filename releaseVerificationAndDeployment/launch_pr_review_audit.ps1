param(
    [ValidateSet("all", "core", "economy", "ew", "party", "interactions")]
    [string]$Suite = "all",
    [ValidateSet("Manual", "Automated")]
    [string]$Mode = "Manual",
    [int]$ResolutionWidth = 1920,
    [int]$ResolutionHeight = 1080,
    [string]$PythonExecutable = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$armaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
$armaExe = Join-Path $armaRoot "arma3_x64.exe"
$missionRoot = Join-Path $armaRoot "Missions\WMP_PR_Review_Audit.VR"
$runRoot = Join-Path $repoRoot ".qa\pr-review-audit"
$profileRoot = Join-Path $runRoot "direct-profile"

if (Get-Process arma3_x64 -ErrorAction SilentlyContinue) {
    throw "Close Arma before staging and launching the PR review audit."
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
$workshopRoot = Join-Path $armaRoot "!Workshop"
$persistenceMod = Get-ChildItem -LiteralPath $workshopRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "@INIDBI2*" } |
    Select-Object -First 1
if ($null -ne $persistenceMod) {
    $mods += $persistenceMod.FullName
    Write-Output "Including optional persistence runtime: $($persistenceMod.Name)"
} else {
    Write-Warning "No INIDBI2 runtime found. The persistence station will verify the disabled dependency-gate path only."
}
$modArgument = '-mod="' + ($mods -join ';') + '"'
New-Item -ItemType Directory -Path $profileRoot -Force | Out-Null
$arguments = @(
    "-noBattlEye", "-showScriptErrors", "-window", "-skipIntro", "-world=empty",
    "-x=$ResolutionWidth", "-y=$ResolutionHeight",
    "-profiles=$profileRoot", "-name=WMPAuditDirect",
    "-init=playMission['','WMP_PR_Review_Audit.VR',true]", $modArgument
)
Start-Process -FilePath $armaExe -ArgumentList $arguments -WorkingDirectory $armaRoot
Write-Output "Launched WMP PR REVIEW AUDIT directly in $Mode mode without opening Eden."
Write-Warning "This launch is local (isServer + hasInterface). Use the dedicated audit separately for client/server and JIP validation."
