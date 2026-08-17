<#
WMP Headless Client Kit - launch_local_dedicated_with_headless.ps1

Stands up a throwaway dedicated server AND one or more headless clients, all on your own machine,
so you can rehearse the full headless-client connection flow before pointing any of this at a real
host. This does not touch your real server.cfg or profiles - everything it creates lives under a
timestamped folder in this repo's .qa\ directory and is safe to delete afterward.

This launches whatever mission is already set as your server's Missions entry below
($MissionTemplate) - point it at a mission that already has Waldo_Headless_Enable = true and at
least one Headless Client slot placed, or this will faithfully demonstrate a headless client
connecting to a mission that never actually uses it.

Example:
  .\launch_local_dedicated_with_headless.ps1 -MissionTemplate "MyMission.Altis" -HeadlessClients 1
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$MissionTemplate,
    [ValidateRange(1, 4)]
    [int]$HeadlessClients = 1,
    [int]$Port = 2402,
    [string]$Password = "wmphc",
    [string[]]$Mods = @("@CBA_A3", "@ace"),
    # A headless client renders nothing, so an uncapped framerate just burns a CPU core for no
    # benefit - a widely recommended headless-client launch parameter. 0 omits -limitFPS entirely.
    [int]$LimitFPS = 10,
    [int]$TimeoutSeconds = 90,
    [string]$ArmaRoot = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($ArmaRoot)) {
    $ArmaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
}
if ([string]::IsNullOrWhiteSpace($ArmaRoot) -or -not (Test-Path -LiteralPath $ArmaRoot)) {
    throw "Arma 3 install path was not found. Pass it explicitly with -ArmaRoot."
}
$serverExe = Join-Path $ArmaRoot "arma3server_x64.exe"
$clientExe = Join-Path $ArmaRoot "arma3_x64.exe"
if (-not (Test-Path -LiteralPath $serverExe)) { throw "Could not find arma3server_x64.exe under '$ArmaRoot'." }
if (-not (Test-Path -LiteralPath $clientExe)) { throw "Could not find arma3_x64.exe under '$ArmaRoot'." }

$modArgument = $null
if ($Mods.Count -gt 0) {
    $resolvedMods = @()
    foreach ($mod in $Mods) {
        if (Test-Path -LiteralPath $mod) {
            $resolvedMods += $mod
        } else {
            $resolvedMods += (Join-Path (Join-Path $ArmaRoot "!Workshop") $mod)
        }
    }
    $modArgument = '-mod="' + ($resolvedMods -join ";") + '"'
}

$runStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runRoot = Join-Path $repoRoot ".qa\headless-client-local\runtime-$runStamp"
$serverProfile = Join-Path $runRoot "server"
New-Item -ItemType Directory -Path $serverProfile -Force | Out-Null

# 127.0.0.1 is correct for both headlessClients[] and localClient[] here - every process this
# script starts runs on this same machine.
$serverConfig = Join-Path $runRoot "server.cfg"
@"
hostname = "WMP Local HC Test";
password = "$Password";
maxPlayers = 8;
persistent = 1;
BattlEye = 0;
verifySignatures = 0;
allowedFilePatching = 2;
headlessClients[] = {"127.0.0.1"};
localClient[] = {"127.0.0.1"};
class Missions
{
    class HcTest
    {
        template = "$MissionTemplate";
        difficulty = "Regular";
    };
};
"@ | Set-Content -LiteralPath $serverConfig -Encoding ASCII

$serverArgs = @(
    "-noBattlEye", "-noSound", "-noPause", "-autoInit",
    "-port=$Port", "-config=$serverConfig", "-profiles=$serverProfile", "-name=WMPHcTestServer"
)
if ($null -ne $modArgument) { $serverArgs += $modArgument }

Write-Output "Starting local dedicated server on port $Port with mission '$MissionTemplate'..."
$server = Start-Process -FilePath $serverExe -ArgumentList $serverArgs -WorkingDirectory $ArmaRoot -PassThru -WindowStyle Hidden
$processes = @($server)

try {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $serverReady = $false
    while ((Get-Date) -lt $deadline -and -not $server.HasExited) {
        Start-Sleep -Milliseconds 500
        $serverRpt = Get-ChildItem -LiteralPath $serverProfile -Filter "*.rpt" -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($null -ne $serverRpt) {
            $missionLoadError = Select-String -LiteralPath $serverRpt.FullName -Pattern "You cannot play/edit this mission|Mission .* was deleted|Missing addons detected" | Select-Object -Last 1
            if ($null -ne $missionLoadError -and $missionLoadError.Line -notmatch "a3_characters_f\s*$") {
                throw ("Arma rejected the mission before startup: " + $missionLoadError.Line)
            }
            $serverReady = [bool](Select-String -LiteralPath $serverRpt.FullName -Pattern "Game started" -Quiet)
            if ($serverReady) { break }
        }
    }
    if (-not $serverReady) { throw "Local dedicated server did not start '$MissionTemplate' within $TimeoutSeconds seconds." }
    Write-Output "Server is up. Starting $HeadlessClients headless client(s)..."

    for ($index = 1; $index -le $HeadlessClients; $index++) {
        $hcProfile = Join-Path $runRoot "headless$index"
        New-Item -ItemType Directory -Path $hcProfile -Force | Out-Null
        $hcArgs = @(
            "-client", "-connect=127.0.0.1", "-port=$Port", "-password=$Password",
            "-profiles=$hcProfile", "-name=WMPHc$index", "-noSound", "-nosplash", "-noPause"
        )
        if ($LimitFPS -gt 0) { $hcArgs += "-limitFPS=$LimitFPS" }
        if ($null -ne $modArgument) { $hcArgs += $modArgument }
        $hc = Start-Process -FilePath $clientExe -ArgumentList $hcArgs -WorkingDirectory $ArmaRoot -PassThru
        $processes += $hc
        Start-Sleep -Seconds 2
    }

    Write-Output ""
    Write-Output "Local dedicated server + $HeadlessClients headless client(s) are running."
    Write-Output "Server profile:   $serverProfile"
    Write-Output "Server RPT:       check the newest .rpt under that folder for connection lines."
    Write-Output "This script leaves everything running - close the started processes yourself, or"
    Write-Output "press Ctrl+C here and re-run with the processes already stopped manually."
}
catch {
    foreach ($process in $processes) {
        if ($null -ne $process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
    }
    throw
}
