<#
WMP Headless Client Kit - launch_headless_client.ps1

Launches ONE headless-client process against a dedicated server that is already running (local or
remote). This is ordinary Arma 3 server hosting, not a WMP script - it just saves you from
hand-typing the -client launch parameters correctly every time.

Before running this:
  1. The mission side must already be set up - Waldo_Headless_Enable = true in
     MissionConfig\headlessConfig.sqf, and at least one Headless Client slot placed and set
     Playable in Eden. See wiki/Headless-Client-Support.md in the main WMP pack.
  2. The dedicated server's server.cfg must allow-list this machine's IP in headlessClients[] -
     see server.cfg.snippet.example in this same folder.
  3. The dedicated server must already be running and have loaded the mission.

A headless client has no window and shows nothing on screen once connected - that is expected, not
a hang. Confirm it worked by checking the server's own RPT log for the connection, and WMP's
`[WMP DIAG]` headless-client diagnostics row once Diagnostics next runs.

Example:
  .\launch_headless_client.ps1 -ServerIP "203.0.113.10" -Port 2302 -Password "yourServerPassword"
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ServerIP,
    [int]$Port = 2302,
    [Parameter(Mandatory = $true)]
    [string]$Password,
    # Mod folder names exactly as they appear under your Arma 3 install's "!Workshop" folder, or
    # full paths if your mods live elsewhere. Must match what the dedicated server is running -
    # a headless client's own modset has to agree with the server's, same as any normal player.
    [string[]]$Mods = @("@CBA_A3", "@ace"),
    [string]$ProfileName = "WMP_HeadlessClient",
    # A headless client renders nothing, so letting it run at an uncapped framerate just burns a CPU
    # core for no benefit - this is a widely recommended headless-client launch parameter, not a WMP
    # invention. Set to 0 to omit -limitFPS entirely and use Arma's own default behaviour instead.
    [int]$LimitFPS = 10,
    # Only needed if Arma 3 is not discoverable via its normal Windows registry install path.
    [string]$ArmaRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ArmaRoot)) {
    $ArmaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
}
if ([string]::IsNullOrWhiteSpace($ArmaRoot) -or -not (Test-Path -LiteralPath $ArmaRoot)) {
    throw "Arma 3 install path was not found. Pass it explicitly with -ArmaRoot."
}
# There is no separate "headless client" executable - the ordinary game executable becomes a
# headless client purely because of the -client launch parameter below (confirmed against Bohemia's
# own headless-client documentation). Running arma3server_x64.exe here would start a SECOND
# dedicated server instead, not a headless client.
$clientExe = Join-Path $ArmaRoot "arma3_x64.exe"
if (-not (Test-Path -LiteralPath $clientExe)) {
    throw "Could not find arma3_x64.exe under '$ArmaRoot'. Pass the correct install path with -ArmaRoot."
}

$profilePath = Join-Path $env:USERPROFILE "Documents\Arma 3 - Other Profiles\$ProfileName"
New-Item -ItemType Directory -Path $profilePath -Force | Out-Null

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

$clientArgs = @(
    "-client",
    "-connect=$ServerIP",
    "-port=$Port",
    "-password=$Password",
    "-profiles=$profilePath",
    "-name=$ProfileName",
    "-noSound",
    "-nosplash",
    "-noPause"
)
if ($LimitFPS -gt 0) { $clientArgs += "-limitFPS=$LimitFPS" }
if ($null -ne $modArgument) { $clientArgs += $modArgument }

Write-Output "Launching headless client -> $ServerIP`:$Port as '$ProfileName'"
Write-Output "  Arma root: $ArmaRoot"
Write-Output "  Profile:   $profilePath"
if ($null -ne $modArgument) { Write-Output "  Mods:      $($Mods -join ', ')" }
Write-Output "This window will show no game UI - that is expected for a headless client. Confirm the connection in the server's own RPT log."

Start-Process -FilePath $clientExe -ArgumentList $clientArgs -WorkingDirectory $ArmaRoot
