param(
    [ValidateSet("core", "acre", "tfar")]
    [string]$ModProfile = "acre",
    [int]$Port = 24142,
    [int]$TimeoutSeconds = 45,
    [string]$PythonExecutable = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$armaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
$serverExe = Join-Path $armaRoot "arma3server_x64.exe"
$missionRoot = Join-Path $armaRoot "MPMissions\WMP_Full_Arma_Audit.VR"
if ((Get-Process arma3_x64 -ErrorAction SilentlyContinue) -or (Get-Process arma3server_x64 -ErrorAction SilentlyContinue)) {
    throw "Close Arma clients and servers before running the mission-load preflight."
}
if ([string]::IsNullOrWhiteSpace($PythonExecutable)) {
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($null -ne $pythonCommand) { $PythonExecutable = $pythonCommand.Source }
}
if ([string]::IsNullOrWhiteSpace($PythonExecutable) -or -not (Test-Path -LiteralPath $PythonExecutable)) {
    throw "Python was not found. Pass -PythonExecutable."
}

& $PythonExecutable (Join-Path $PSScriptRoot "build_full_arma_audit.py") --destination $missionRoot --suite all --mod-profile $ModProfile --mode manual
if ($LASTEXITCODE -ne 0) { throw "Full-pack audit staging failed." }

$modNames = switch ($ModProfile) {
    "core" { @("@CBA_A3", "@ace", "@Zeus Enhanced") }
    "acre" { @("@CBA_A3", "@ace", "@Zeus Enhanced", "@ACRE2") }
    "tfar" { @("@CBA_A3", "@ace", "@Zeus Enhanced", "@Task Force Arrowhead Radio (BETA!!!)") }
}
$mods = foreach ($name in $modNames) {
    $path = Join-Path (Join-Path $armaRoot "!Workshop") $name
    if (-not (Test-Path -LiteralPath $path)) { throw "Required preflight mod is not installed: $name" }
    $path
}
$modArgument = '-mod="' + ($mods -join ';') + '"'
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runRoot = Join-Path $repoRoot ".qa\full-arma-audit\mission-load-$stamp"
$profileRoot = Join-Path $runRoot "server"
New-Item -ItemType Directory -Path $profileRoot -Force | Out-Null
$serverConfig = Join-Path $runRoot "server.cfg"
@"
hostname = "WMP Mission Load Preflight";
maxPlayers = 1;
persistent = 0;
BattlEye = 0;
verifySignatures = 0;
class Missions
{
    class Audit
    {
        template = "WMP_Full_Arma_Audit.VR";
        difficulty = "Regular";
    };
};
"@ | Set-Content -LiteralPath $serverConfig -Encoding ASCII

$arguments = @(
    "-noBattlEye", "-noSound", "-noPause", "-autoInit",
    "-port=$Port", "-config=$serverConfig", "-profiles=$profileRoot", "-name=WMPMissionLoadPreflight",
    $modArgument
)
$server = Start-Process -FilePath $serverExe -ArgumentList $arguments -PassThru -WindowStyle Hidden
try {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $rpt = $null
    while ((Get-Date) -lt $deadline -and -not $server.HasExited) {
        Start-Sleep -Milliseconds 250
        $rpt = Get-ChildItem -LiteralPath $profileRoot -Filter "*.rpt" -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($null -eq $rpt) { continue }
        $rejection = Select-String -LiteralPath $rpt.FullName -Pattern "You cannot play/edit this mission|Mission .* was deleted|Missing addons detected" | Select-Object -Last 1
        if ($null -ne $rejection) {
            throw ("Arma rejected WMP FULL PACK AUDIT: " + $rejection.Line)
        }
        if (Select-String -LiteralPath $rpt.FullName -Pattern "Mission world: VR" -Quiet) {
            Write-Output ("WMP FULL PACK AUDIT mission-load preflight passed. RPT: " + $rpt.FullName)
            exit 0
        }
    }
    throw "WMP FULL PACK AUDIT did not enter the VR mission within $TimeoutSeconds seconds."
}
finally {
    if ($null -ne $server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
    }
}
