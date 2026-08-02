<#
 * Author: WaldoTheWarfighter
 * Stages the canonical full-pack audit mission, starts its dedicated authority and connects a
 * windowed Arma client without opening Eden. The checked launch always disables BattlEye and
 * keeps server/client profiles inside the repository QA workspace for report inspection.
 *
 * Parameters:
 * Suite: feature subset to stage (default all).
 * Mode: manual stations or automated audit execution (default Manual).
 * Port: dedicated-server port (default 24132).
 * ResolutionWidth/ResolutionHeight: connected client dimensions (default 3840x2160).
 * ExcludePersistenceMod: omit any installed INIDBI2 runtime to test its dependency gate.
 * PythonExecutable: optional explicit interpreter used to assemble the mission.
 *
 * Example:
 * powershell -ExecutionPolicy Bypass -File .\releaseVerificationAndDeployment\launch_pr_review_audit.ps1 -Suite all -Mode Manual
 * Current callers: launch_full_arma_hosted_audit.ps1 and manual QA operators.
 #>
param(
    [ValidateSet("all", "core", "economy", "ew", "party", "interactions")]
    [string]$Suite = "all",
    [ValidateSet("Manual", "Automated")]
    [string]$Mode = "Manual",
    [int]$Port = 24132,
    [int]$ResolutionWidth = 3840,
    [int]$ResolutionHeight = 2160,
    [switch]$ExcludePersistenceMod,
    [string]$PythonExecutable = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$armaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
$armaExe = Join-Path $armaRoot "arma3_x64.exe"
$serverExe = Join-Path $armaRoot "arma3server_x64.exe"
$missionRoot = Join-Path $armaRoot "MPMissions\WMP_PR_Review_Audit.VR"
$runRoot = Join-Path $repoRoot ".qa\pr-review-audit"
$serverProfile = Join-Path $runRoot "server-profile"
$clientProfile = Join-Path $runRoot "client-profile"
$serverConfig = Join-Path $runRoot "server.cfg"

if ((Get-Process arma3_x64 -ErrorAction SilentlyContinue) -or (Get-Process arma3server_x64 -ErrorAction SilentlyContinue)) {
    throw "Close Arma clients and servers before staging and launching the full-pack PR audit."
}
if ([string]::IsNullOrWhiteSpace($PythonExecutable)) {
    $PythonExecutable = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
}
if (-not (Test-Path -LiteralPath $PythonExecutable)) { throw "Python was not found." }

& $PythonExecutable (Join-Path $PSScriptRoot "build_pr_review_audit.py") --destination $missionRoot --suite $Suite --mode $Mode.ToLowerInvariant()
if ($LASTEXITCODE -ne 0) { throw "Full-pack PR audit staging failed." }

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
if ($ExcludePersistenceMod) {
    Write-Warning "INIDBI2 intentionally excluded. The persistence station must report the unavailable dependency-gate path."
} elseif ($null -ne $persistenceMod) {
    $mods += $persistenceMod.FullName
    Write-Output "Including optional persistence runtime: $($persistenceMod.Name)"
} else {
    Write-Warning "No INIDBI2 runtime found. The persistence station will verify the disabled dependency-gate path only."
}
$modArgument = '-mod="' + ($mods -join ';') + '"'
New-Item -ItemType Directory -Path $serverProfile -Force | Out-Null
New-Item -ItemType Directory -Path $clientProfile -Force | Out-Null
@"
hostname = "WMP Full Pack PR Audit";
maxPlayers = 5;
persistent = 1;
BattlEye = 0;
verifySignatures = 0;
allowedFilePatching = 0;
class Missions
{
    class FullPackPrAudit
    {
        template = "WMP_PR_Review_Audit.VR";
        difficulty = "Regular";
    };
};
"@ | Set-Content -LiteralPath $serverConfig -Encoding ASCII

$serverArguments = @(
    "-noBattlEye", "-noSound", "-noPause", "-autoInit", "-port=$Port",
    "-config=$serverConfig", "-profiles=$serverProfile", "-name=WMPAuditServer", $modArgument
)
$server = Start-Process -FilePath $serverExe -ArgumentList $serverArguments -WorkingDirectory $armaRoot -PassThru -WindowStyle Hidden
$serverReady = $false
$serverDeadline = (Get-Date).AddSeconds(90)
while ((Get-Date) -lt $serverDeadline -and -not $server.HasExited) {
    Start-Sleep -Milliseconds 500
    $serverRpt = Get-ChildItem -LiteralPath $serverProfile -Filter "*.rpt" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -ne $serverRpt) {
        $loadError = Select-String -LiteralPath $serverRpt.FullName -Pattern "You cannot play/edit this mission|Mission .* was deleted|Missing addons detected" | Select-Object -Last 1
        if ($null -ne $loadError -and $loadError.Line -notmatch "a3_characters_f\s*$") {
            Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
            throw ("Arma rejected the staged audit mission: " + $loadError.Line)
        }
        $serverReady = [bool](Select-String -LiteralPath $serverRpt.FullName -Pattern "Mission world: VR|Game started|WMP PR REVIEW AUDIT" -Quiet)
        if ($serverReady) { break }
    }
}
if (-not $serverReady) {
    Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
    throw "The dedicated audit authority did not load WMP_PR_Review_Audit.VR."
}

$clientArguments = @(
    "-noBattlEye", "-showScriptErrors", "-window", "-noPause", "-skipIntro", "-world=empty",
    "-connect=localhost", "-port=$Port", "-x=$ResolutionWidth", "-y=$ResolutionHeight",
    "-profiles=$clientProfile", "-name=WMPAuditClient", $modArgument
)
$client = Start-Process -FilePath $armaExe -ArgumentList $clientArguments -WorkingDirectory $armaRoot -PassThru
Write-Output "Loaded WMP_PR_Review_Audit.VR on dedicated authority PID $($server.Id)."
Write-Output "Connected ${ResolutionWidth}x${ResolutionHeight} audit client PID $($client.Id) in $Mode mode; Eden is not used."
Write-Output "Choose a playable slot and press OK if the role-assignment screen is shown."
