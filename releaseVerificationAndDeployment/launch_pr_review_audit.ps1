<#
 * Author: WaldoTheWarfighter
 * Stages the canonical full-pack audit mission, starts its dedicated authority and connects a
 * windowed Arma client without opening Eden. The checked launch always disables BattlEye and
 * creates fresh timestamped server/client profiles inside the repository QA workspace. INIDBI2
 * is loaded only by the server; the client receives only the four required gameplay/UI mods.
 *
 * Parameters:
 * Suite: feature subset to stage (default all).
 * Mode: manual stations, automated audit execution, or the documentation theme gallery
 * capture sequence (default Manual).
 * Port: dedicated-server port (default 24132).
 * ResolutionWidth/ResolutionHeight: connected client dimensions (default 3840x2160).
 * ExcludePersistenceMod: omit any installed INIDBI2 runtime to test its dependency gate.
 * IncludeRhsPolaris: legacy compatibility switch to load RHSUSAF. The seat station remains the
 *   vanilla NATO Prowler/DAGOR regardless of this switch.
 * IncludeLambs: load the installed LAMBS Danger, Turrets, Suppression and RPG suite for the
 *   paired Cortex ownership/handover audit. Omit it to exercise Cortex's standalone fallback.
 * HeadlessClients: number of local headless owners to launch (0-2, default 0).
 * CortexAudit: run the disposable Cortex owner, convoy, artillery and custom UI acceptance cases.
 * CortexFocus: optional focused batch; stateflows runs lifecycle and vehicle state handoffs together.
 * PythonExecutable: optional explicit interpreter used to assemble the mission.
 * Runtime evidence: .qa/pr-review-audit/runtime-<timestamp>/{server,client}. Both processes always
 * enable Arma's network log so every dedicated audit captures traffic alongside its RPT.
 *
 * Example:
 * powershell -ExecutionPolicy Bypass -File .\releaseVerificationAndDeployment\launch_pr_review_audit.ps1 -Suite all -Mode Manual
 * Current callers: launch_full_arma_hosted_audit.ps1 and manual QA operators.
 #>
param(
    [ValidateSet("all", "core", "economy", "ew", "party", "interactions")]
    [string]$Suite = "all",
    [ValidateSet("Manual", "Automated", "ThemeGallery")]
    [string]$Mode = "Manual",
    [int]$Port = 24132,
    [int]$ResolutionWidth = 3840,
    [int]$ResolutionHeight = 2160,
    [switch]$ExcludePersistenceMod,
    [switch]$IncludeRhsPolaris,
    [switch]$IncludeLambs,
    [ValidateRange(0, 2)]
    [int]$HeadlessClients = 0,
    [switch]$CortexAudit,
    [ValidateSet("all", "features", "artillery", "convoy", "infantry", "combat", "mechanics", "convoymatrix", "convoycolumn", "convoytracked", "convoydiagnostic", "convoyfollow", "gates", "gunnery", "convoyseats", "extensions", "landing", "cover", "avoidance", "crossing", "contact", "artillerysmoke", "scheduler", "profiles", "lighting", "performance", "performancecontact", "performancemixed", "coordinated", "coordinatedbounds", "coordinatedclean", "lifecycle", "stateflows", "lambs", "aircraft", "deceleration", "reactions", "support", "airborne", "vehicles", "fire", "buildings")]
    [string]$CortexFocus = "all",
    [ValidateSet("FLANK-NATIVE-FIRE","FLANK-YELLOW-NATIVE-FIRE","FLANK-YELLOW","FLANK-AWARE","ADVANCE-AWARE","FLANK","ADVANCE","ADVANCE-YELLOW","ADVANCE-CLOSE","ADVANCE-DISTANT","FLANK-ZEUS","ADVANCE-ZEUS","FLANK-ZEUS-ROE","FLANK-BLOCKED","ADVANCE-BLOCKED","FLANK-GRENADE","FLANK-ZEUS-CONSOLIDATE","ADVANCE-GRENADE")]
    [string]$CortexCombatCase = "",
    [string]$PythonExecutable = ""
)

$ErrorActionPreference = "Stop"
if ($CortexCombatCase -and (-not $CortexAudit -or $CortexFocus -ne "combat")) { throw "CortexCombatCase requires -CortexAudit -CortexFocus combat; omit it for full coverage." }
$repoRoot = Split-Path -Parent $PSScriptRoot
$armaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
$armaExe = Join-Path $armaRoot "arma3_x64.exe"
$serverExe = Join-Path $armaRoot "arma3server_x64.exe"
$missionRoot = Join-Path $armaRoot "MPMissions\WMP_PR_Review_Audit.VR"
$runStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runRoot = Join-Path $repoRoot ".qa\pr-review-audit\runtime-$runStamp"
$serverProfile = Join-Path $runRoot "server"
$clientProfile = Join-Path $runRoot "client"
$serverConfig = Join-Path $runRoot "server.cfg"

if ((Get-Process arma3_x64 -ErrorAction SilentlyContinue) -or (Get-Process arma3server_x64 -ErrorAction SilentlyContinue)) {
    throw "Close Arma clients and servers before staging and launching the full-pack PR audit."
}
if ([string]::IsNullOrWhiteSpace($PythonExecutable)) {
    $PythonExecutable = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
}
if (-not (Test-Path -LiteralPath $PythonExecutable)) { throw "Python was not found." }

$buildMode = if ($Mode -eq "ThemeGallery") { "theme-gallery" } else { $Mode.ToLowerInvariant() }
& $PythonExecutable (Join-Path $PSScriptRoot "build_pr_review_audit.py") --destination $missionRoot --suite $Suite --mode $buildMode
if ($LASTEXITCODE -ne 0) { throw "Full-pack PR audit staging failed." }
if ($CortexAudit) {
    if ($CortexCombatCase) {
        Add-Content -LiteralPath (Join-Path $missionRoot "auditPreInit.sqf") -Value ('missionNamespace setVariable ["Waldo_CortexQA_CombatCase","' + $CortexCombatCase + '"];')
    }
    Add-Content -LiteralPath (Join-Path $missionRoot "auditPreInit.sqf") -Value ('missionNamespace setVariable ["Waldo_CortexQA_Focus","' + $CortexFocus + '"];')
    $coverage = Get-Content -LiteralPath (Join-Path $PSScriptRoot "cortexQA/coverage.json") -Raw | ConvertFrom-Json
    $catalogue = @($coverage.cases | ForEach-Object {
        $case = $_
        $fields = @($case.id, $case.title, $case.status, $case.automation) | ForEach-Object { '"' + ([string]$_).Replace('"', '""') + '"' }
        '[' + ($fields -join ',') + ']'
    })
    Add-Content -LiteralPath (Join-Path $missionRoot "auditPreInit.sqf") -Value ('missionNamespace setVariable ["Waldo_CortexQA_Catalogue",[' + ($catalogue -join ',') + ']];')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runConvoySeats.sqf") -Destination (Join-Path $missionRoot "cortexQASeats.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runLanding.sqf") -Destination (Join-Path $missionRoot "cortexQALanding.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runConvoyAvoidance.sqf") -Destination (Join-Path $missionRoot "cortexQAAvoidance.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runArtillerySmoke.sqf") -Destination (Join-Path $missionRoot "cortexQAArtillerySmoke.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runScheduler.sqf") -Destination (Join-Path $missionRoot "cortexQAScheduler.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runPerformance.sqf") -Destination (Join-Path $missionRoot "cortexQAPerformance.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runPerformanceContact.sqf") -Destination (Join-Path $missionRoot "cortexQAPerformanceContact.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runPerformanceOwner.sqf") -Destination (Join-Path $missionRoot "cortexQAPerformanceOwner.sqf")
    Add-Content -LiteralPath (Join-Path $missionRoot "auditPreInit.sqf") -Value 'call compile preprocessFileLineNumbers "cortexQAPerformanceOwner.sqf";'
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runProfiles.sqf") -Destination (Join-Path $missionRoot "cortexQAProfiles.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runLighting.sqf") -Destination (Join-Path $missionRoot "cortexQALighting.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runMultiManoeuvre.sqf") -Destination (Join-Path $missionRoot "cortexQAMultiManoeuvre.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runCoordinated.sqf") -Destination (Join-Path $missionRoot "cortexQACoordinated.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runLifecycle.sqf") -Destination (Join-Path $missionRoot "cortexQALifecycle.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runLambs.sqf") -Destination (Join-Path $missionRoot "cortexQALambs.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runDeceleration.sqf") -Destination (Join-Path $missionRoot "cortexQADeceleration.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runAircraft.sqf") -Destination (Join-Path $missionRoot "cortexQAAircraft.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runContact.sqf") -Destination (Join-Path $missionRoot "cortexQAContact.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runCrossing.sqf") -Destination (Join-Path $missionRoot "cortexQACrossing.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runCover.sqf") -Destination (Join-Path $missionRoot "cortexQACover.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runGates.sqf") -Destination (Join-Path $missionRoot "cortexQAGates.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runGunnery.sqf") -Destination (Join-Path $missionRoot "cortexQAGunnery.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runGuide.sqf") -Destination (Join-Path $missionRoot "cortexQAGuide.sqf")
    Add-Content -LiteralPath (Join-Path $missionRoot "description.ext") -Value 'skipLobby = 1;'
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runBuildingComparison.sqf") -Destination (Join-Path $missionRoot "cortexQABuildings.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runConvoyMatrix.sqf") -Destination (Join-Path $missionRoot "cortexQAConvoyMatrix.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runFireControl.sqf") -Destination (Join-Path $missionRoot "cortexQAFire.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runVehicleDrills.sqf") -Destination (Join-Path $missionRoot "cortexQAVehicles.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runAirborne.sqf") -Destination (Join-Path $missionRoot "cortexQAAirborne.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runSupport.sqf") -Destination (Join-Path $missionRoot "cortexQASupport.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runReactions.sqf") -Destination (Join-Path $missionRoot "cortexQAReactions.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runMechanics.sqf") -Destination (Join-Path $missionRoot "cortexQAMechanics.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runCombat.sqf") -Destination (Join-Path $missionRoot "cortexQACombat.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runServer.sqf") -Destination (Join-Path $missionRoot "cortexQAServer.sqf")
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "cortexQA/runClient.sqf") -Destination (Join-Path $missionRoot "cortexQAClient.sqf")
    Add-Content -LiteralPath (Join-Path $missionRoot "auditInitServer.sqf") -Value '[] execVM "cortexQAServer.sqf";'
    Add-Content -LiteralPath (Join-Path $missionRoot "auditInitPlayerLocal.sqf") -Value '[] execVM "cortexQAClient.sqf";'

}
if ($HeadlessClients -gt 0) {
    Add-Content -LiteralPath (Join-Path $missionRoot "auditPreInit.sqf") -Encoding UTF8 -Value '
missionNamespace setVariable ["Waldo_Headless_Enable", true];
missionNamespace setVariable ["Waldo_Headless_StartDelaySeconds", 1000000];
'
}

if ($CortexAudit) {
    # Fingerprint the exact disposable mission payload after every source and runtime option is staged.
    # auditPreInit.sqf receives the marker only after hashing so the fingerprint cannot include its own marker.
    $fingerprintEntries = Get-ChildItem -LiteralPath $missionRoot -Recurse -File |
        Sort-Object FullName |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($missionRoot.Length).TrimStart('\').Replace('\', '/')
            $fileHash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            "$relativePath|$fileHash"
        }
    $fingerprintPayload = [string]::Join("`n", $fingerprintEntries)
    $fingerprintBytes = [System.Text.Encoding]::UTF8.GetBytes($fingerprintPayload)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $sourceFingerprint = ([System.BitConverter]::ToString($sha256.ComputeHash($fingerprintBytes))).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha256.Dispose()
    }
    Add-Content -LiteralPath (Join-Path $missionRoot "auditPreInit.sqf") -Value ('missionNamespace setVariable ["Waldo_CortexQA_SourceFingerprint","' + $sourceFingerprint + '"]; diag_log "WMP CORTEX QA SOURCE|fingerprint=' + $sourceFingerprint + '";')
    New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $runRoot "cortex-source-fingerprint.txt") -Value $sourceFingerprint -Encoding ASCII
}


$modNames = @("@CBA_A3", "@ace", "@Zeus Enhanced", "@ACRE2")
$clientMods = foreach ($name in $modNames) {
    $path = Join-Path (Join-Path $armaRoot "!Workshop") $name
    if (-not (Test-Path -LiteralPath $path)) { throw "Required audit mod is not installed: $name" }
    $path
}
$serverMods = @($clientMods)
$workshopRoot = Join-Path $armaRoot "!Workshop"
if ($IncludeLambs) {
    $lambsNames = @("@LAMBS_Danger.fsm", "@LAMBS_Turrets", "@LAMBS_Suppression", "@LAMBS_RPG")
    foreach ($name in $lambsNames) {
        $lambsPath = Join-Path $workshopRoot $name
        if (-not (Test-Path -LiteralPath $lambsPath)) { throw "LAMBS paired audit requires installed Workshop mod: $name" }
        $clientMods += $lambsPath
        $serverMods += $lambsPath
    }
    Write-Output "Including the installed LAMBS suite for the Cortex compatibility arm."
}
if ($IncludeRhsPolaris) {
    $rhsPath = Join-Path $workshopRoot "@RHSUSAF"
    if (-not (Test-Path -LiteralPath $rhsPath)) { throw "RHSUSAF is required for -IncludeRhsPolaris but is not installed." }
    $clientMods += $rhsPath
    $serverMods += $rhsPath
    Write-Output "Including optional RHSUSAF; seat station remains the NATO Prowler/DAGOR."
}
$persistenceMod = Get-ChildItem -LiteralPath $workshopRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "@INIDBI2*" } |
    Select-Object -First 1
if ($ExcludePersistenceMod) {
    Write-Warning "INIDBI2 intentionally excluded. The persistence station must report the unavailable dependency-gate path."
} elseif ($null -ne $persistenceMod) {
    $serverMods += $persistenceMod.FullName
    Write-Output "Including optional persistence runtime: $($persistenceMod.Name)"
} else {
    Write-Warning "No INIDBI2 runtime found. The persistence station will verify the disabled dependency-gate path only."
}
$serverModArgument = '-mod="' + ($serverMods -join ';') + '"'
$clientModArgument = '-mod="' + ($clientMods -join ';') + '"'
New-Item -ItemType Directory -Path $serverProfile -Force | Out-Null
New-Item -ItemType Directory -Path $clientProfile -Force | Out-Null
@"
hostname = "WMP Full Pack PR Audit";
password = "wmpqa";
passwordAdmin = "wmpqa";
maxPlayers = 7;
headlessClients[] = {"127.0.0.1"};
localClient[] = {"127.0.0.1"};
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
    "-noBattlEye", "-netlog", "-noSound", "-noPause", "-autoInit", "-port=$Port",
    "-config=$serverConfig", "-profiles=$serverProfile", "-name=WMPAuditServer", $serverModArgument
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

for ($hcIndex = 1; $hcIndex -le $HeadlessClients; $hcIndex++) {
    $hcProfile = Join-Path $runRoot "headless-$hcIndex"
    New-Item -ItemType Directory -Path $hcProfile -Force | Out-Null
    $hcArguments = @("-client", "-connect=127.0.0.1", "-port=$Port", "-password=wmpqa", "-noBattlEye", "-netlog", "-noSound", "-noPause", "-profiles=$hcProfile", "-name=WMPAuditHC$hcIndex", $clientModArgument)
    $hcProcess = Start-Process -FilePath $serverExe -ArgumentList $hcArguments -WorkingDirectory $armaRoot -PassThru -WindowStyle Hidden
    Write-Output "Started audit headless client $hcIndex PID $($hcProcess.Id)."
}

$clientArguments = @(
    "-noBattlEye", "-netlog", "-noSplash", "-showScriptErrors", "-window", "-noPause", "-skipIntro", "-world=empty",
    "-connect=localhost", "-port=$Port", "-x=$ResolutionWidth", "-y=$ResolutionHeight",
    "-windowWidth=$ResolutionWidth", "-windowHeight=$ResolutionHeight",
    "-password=wmpqa", "-profiles=$clientProfile", "-name=WMPAuditClient", $clientModArgument
)
$client = Start-Process -FilePath $armaExe -ArgumentList $clientArguments -WorkingDirectory $armaRoot -PassThru
Write-Output "Loaded WMP_PR_Review_Audit.VR on dedicated authority PID $($server.Id)."
Write-Output "Started ${ResolutionWidth}x${ResolutionHeight} audit client PID $($client.Id) in $Mode mode; Eden is not used."
if ($CortexAudit) {
    Write-Output "Cortex audit automatically enters the first playable slot. Runtime evidence: $runRoot"
} else {
    Write-Output "Choose a playable slot and press OK when the role-assignment screen appears. Runtime evidence: $runRoot"
}
