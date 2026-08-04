<#
 * Author: WaldoTheWarfighter
 * Stages and launches the purpose-built four-slot ACRE2 respawn test on dedicated authority. The
 * launch refuses to proceed unless the staged config still contains the ALPHA and BRAVO plans.
 * Existing Arma client/server processes must be closed first so staged files cannot remain locked.
 *
 * Parameters: Port and client resolution; defaults are 24142 and 3840x2160.
 * Return Value: starts one hidden server and one visible client, then prints PIDs/evidence path.
 * Example: .\releaseVerificationAndDeployment\launch_acre2_respawn_test.ps1
 * Result: opens the multiplayer role screen without Eden and with BattlEye disabled.
 * Current callers: manual ACRE lifecycle, CEOI, Babel and respawn verification.
 #>
param([int]$Port = 24142, [int]$ResolutionWidth = 3840, [int]$ResolutionHeight = 2160)
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$armaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
if ((Get-Process arma3_x64 -ErrorAction SilentlyContinue) -or (Get-Process arma3server_x64 -ErrorAction SilentlyContinue)) {
    throw "Close all Arma clients and servers before launching the ACRE2 respawn test."
}
$source = Join-Path $PSScriptRoot "serverTestMissions\WMP_ACRE2_Respawn_Test.VR"
$missionRoot = Join-Path $armaRoot "MPMissions\WMP_ACRE2_Respawn_Test.VR"
if (Test-Path -LiteralPath $missionRoot) {Remove-Item -LiteralPath $missionRoot -Recurse -Force}
Copy-Item -LiteralPath $source -Destination $missionRoot -Recurse -Force
$stagedConfig = Get-Content (Join-Path $missionRoot "MissionConfig\acreConfig.sqf") -Raw
if ($stagedConfig -notmatch '"ALPHA_NET"' -or $stagedConfig -notmatch '"BRAVO_NET"') {
    throw "Preflight failed: the staged ACRE test config does not contain ALPHA_NET and BRAVO_NET."
}
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runRoot = Join-Path $repoRoot ".qa\acre-test\runtime-$stamp"
$serverProfile = Join-Path $runRoot "server"
$clientProfile = Join-Path $runRoot "client"
New-Item -ItemType Directory -Path $serverProfile, $clientProfile -Force | Out-Null
$serverConfig = Join-Path $runRoot "server.cfg"
@"
hostname="WMP ACRE2 Respawn Test";
password="wmpqa";
passwordAdmin="wmpqa";
maxPlayers=4;
persistent=1;
BattlEye=0;
verifySignatures=0;
class Missions { class AcreRespawnTest { template="WMP_ACRE2_Respawn_Test.VR"; difficulty="Regular"; }; };
"@ | Set-Content -LiteralPath $serverConfig -Encoding ASCII
$mods = @("@CBA_A3", "@ace", "@Zeus Enhanced", "@ACRE2") | ForEach-Object {Join-Path "$armaRoot\!Workshop" $_}
foreach ($mod in $mods) {if (!(Test-Path -LiteralPath $mod)) {throw "Required mod is missing: $mod"}}
$modArgument = '-mod="' + ($mods -join ';') + '"'
$server = Start-Process (Join-Path $armaRoot "arma3server_x64.exe") -ArgumentList @(
    "-noBattlEye", "-noSound", "-noPause", "-autoInit", "-port=$Port", "-config=$serverConfig",
    "-profiles=$serverProfile", "-name=WMPAcreServer", $modArgument
) -WorkingDirectory $armaRoot -PassThru -WindowStyle Hidden
$deadline = (Get-Date).AddSeconds(55)
$ready = $false
while ((Get-Date) -lt $deadline -and !$server.HasExited) {
    Start-Sleep -Milliseconds 500
    $rpt = Get-ChildItem $serverProfile -Filter "*.rpt" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($rpt -and (Select-String $rpt.FullName -Pattern "Mission world: VR" -Quiet)) {$ready = $true; break}
}
if (!$ready) {if (!$server.HasExited) {Stop-Process $server.Id -Force}; throw "Dedicated test mission did not load."}
$client = Start-Process (Join-Path $armaRoot "arma3_x64.exe") -ArgumentList @(
    "-noBattlEye", "-noSplash", "-showScriptErrors", "-window", "-noPause", "-skipIntro", "-world=empty",
    "-connect=localhost", "-port=$Port", "-x=$ResolutionWidth", "-y=$ResolutionHeight", "-password=wmpqa",
    "-profiles=$clientProfile", "-name=WMPAcreClient", $modArgument
) -WorkingDirectory $armaRoot -PassThru
Write-Output "ACRE test preflight passed: ALPHA_NET and BRAVO_NET are staged."
Write-Output "Server PID $($server.Id); client PID $($client.Id); evidence $runRoot"
