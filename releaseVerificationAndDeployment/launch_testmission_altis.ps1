<#
 * Author: WaldoTheWarfighter
 * Stages the user's maintained TestMission.Altis under a disposable multiplayer name, starts a
 * hidden dedicated server and connects a playable client, never Eden. The mission must already
 * exist in the Waldo profile mission folder and must be updated separately. The launcher refuses to
 * stack another Arma client/server, checks required mods and uses the pack's standard no-BattlEye
 * 3840x2160 manual-test presentation.
 *
 * Parameters:
 * ResolutionWidth: client width in pixels (default 3840).
 * ResolutionHeight: client height in pixels (default 2160).
 *
 * Return Value: starts Arma and prints the process ID plus the RPT directory.
 *
 * Example:
 * .\releaseVerificationAndDeployment\launch_testmission_altis.ps1
 *
 * Current callers: manual TestMission.Altis regression testing.
 #>
param([int]$Port = 24152, [int]$ResolutionWidth = 3840, [int]$ResolutionHeight = 2160)
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

if ((Get-Process arma3_x64 -ErrorAction SilentlyContinue) -or (Get-Process arma3server_x64 -ErrorAction SilentlyContinue)) {
    throw "Close all Arma clients and servers before launching TestMission.Altis."
}

$armaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
$missionRoot = Join-Path $env:USERPROFILE "OneDrive\Documents\Arma 3 - Other Profiles\Waldo\missions\TestMission.Altis"
if (!(Test-Path -LiteralPath (Join-Path $missionRoot "mission.sqm"))) {
    throw "TestMission.Altis was not found at $missionRoot"
}

$staleAceCompat = Get-ChildItem -LiteralPath (Join-Path $missionRoot "MissionScripts") -File -Recurse -ErrorAction SilentlyContinue |
    Select-String -Pattern "AceSetNameRespawnCompat|Waldo_ACE_SetNameCompatInstalled|ace-nametags-respawn-compat" -List
if ($staleAceCompat) {
    throw "TestMission.Altis contains the removed ACE setName compatibility implementation: $($staleAceCompat.Path -join ', '). Synchronize the current pack before launch."
}

$mods = @("@CBA_A3", "@ace", "@Zeus Enhanced", "@ACRE2") | ForEach-Object {
    Join-Path (Join-Path $armaRoot "!Workshop") $_
}
foreach ($mod in $mods) {
    if (!(Test-Path -LiteralPath $mod)) {throw "Required test mod is not installed: $mod"}
}
$modArgument = '-mod="' + ($mods -join ';') + '"'
$stagedMission = Join-Path $armaRoot "MPMissions\WMP_TestMission_Regression.Altis"
if (Test-Path -LiteralPath $stagedMission) {Remove-Item -LiteralPath $stagedMission -Recurse -Force}
Copy-Item -LiteralPath $missionRoot -Destination $stagedMission -Recurse -Force

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runRoot = Join-Path $repoRoot ".qa\testmission-runtime\runtime-$stamp"
$serverProfile = Join-Path $runRoot "server"
$clientProfile = Join-Path $runRoot "client"
New-Item -ItemType Directory -Path $serverProfile, $clientProfile -Force | Out-Null
$serverConfig = Join-Path $runRoot "server.cfg"
@"
hostname="WMP TestMission Regression";
password="wmpqa";
passwordAdmin="wmpqa";
maxPlayers=31;
persistent=1;
BattlEye=0;
verifySignatures=0;
class Missions { class TestMissionRegression { template="WMP_TestMission_Regression.Altis"; difficulty="Regular"; }; };
"@ | Set-Content -LiteralPath $serverConfig -Encoding ASCII

$server = Start-Process (Join-Path $armaRoot "arma3server_x64.exe") -ArgumentList @(
    "-noBattlEye", "-noSound", "-noPause", "-autoInit", "-port=$Port", "-config=$serverConfig",
    "-profiles=$serverProfile", "-name=WMPTestServer", $modArgument
) -WorkingDirectory $armaRoot -PassThru -WindowStyle Hidden
$deadline = (Get-Date).AddSeconds(60)
$ready = $false
while ((Get-Date) -lt $deadline -and !$server.HasExited) {
    Start-Sleep -Milliseconds 500
    $serverRpt = Get-ChildItem $serverProfile -Filter "*.rpt" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($serverRpt -and (Select-String $serverRpt.FullName -Pattern "Mission world: Altis" -Quiet)) {$ready = $true; break}
}
if (!$ready) {
    if (!$server.HasExited) {Stop-Process $server.Id -Force}
    throw "Dedicated TestMission server did not reach Altis. Inspect $serverProfile"
}

$client = Start-Process (Join-Path $armaRoot "arma3_x64.exe") -ArgumentList @(
    "-noBattlEye", "-noSplash", "-showScriptErrors", "-window", "-noPause", "-skipIntro", "-world=empty",
    "-connect=localhost", "-port=$Port", "-password=wmpqa", "-x=$ResolutionWidth", "-y=$ResolutionHeight",
    "-profiles=$clientProfile", "-name=WMPTestClient", $modArgument
) -WorkingDirectory $armaRoot -PassThru
Write-Output "TestMission dedicated server PID $($server.Id); client PID $($client.Id); evidence $runRoot"
