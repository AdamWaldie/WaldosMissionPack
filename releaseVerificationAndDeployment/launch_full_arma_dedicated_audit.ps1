param(
    [ValidateSet("all", "core", "economy", "ew", "party", "interactions")]
    [string]$Suite = "all",
    [ValidateSet("core", "acre", "tfar")]
    [string]$ModProfile = "acre",
    [ValidateRange(1, 5)]
    [int]$Clients = 1,
    [int]$Port = 24132,
    [int]$TimeoutSeconds = 240,
    [ValidateRange(1280, 3840)]
    [int]$ResolutionWidth = 2560,
    [ValidateRange(720, 2160)]
    [int]$ResolutionHeight = 1440,
    [string]$PythonExecutable = "",
    [switch]$LeaveClientsOpen
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$armaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
$serverExe = Join-Path $armaRoot "arma3server_x64.exe"
$clientExe = Join-Path $armaRoot "arma3_x64.exe"
$missionRoot = Join-Path $armaRoot "MPMissions\WMP_Full_Arma_Audit.VR"
if ((Get-Process arma3_x64 -ErrorAction SilentlyContinue) -or (Get-Process arma3server_x64 -ErrorAction SilentlyContinue)) {
    throw "Close all Arma audit clients and servers before staging. While they are open, only monitor RPT files and record findings."
}
foreach ($legacyName in ("WMP_Full_Arma_Audit.VR", "WMP_FULL_PACK_AUDIT.VR")) {
    $legacyRoot = Join-Path $armaRoot ("MPMissions\" + $legacyName)
    if (Test-Path -LiteralPath $legacyRoot) {
        Remove-Item -LiteralPath $legacyRoot -Recurse -Force
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
& $PythonExecutable (Join-Path $PSScriptRoot "build_full_arma_audit.py") --destination $missionRoot --suite $Suite --mod-profile $ModProfile --mode automated
if ($LASTEXITCODE -ne 0) { throw "Full audit mission assembly failed." }

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
$modArgument = if ($mods.Count -gt 0) { '-mod="' + ($mods -join ';') + '"' } else { $null }

$runStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runRoot = Join-Path $repoRoot ".qa\full-arma-audit\runtime-$Suite-$ModProfile-$runStamp"
$serverProfile = Join-Path $runRoot "server"
New-Item -ItemType Directory -Path $serverProfile -Force | Out-Null
$serverConfig = Join-Path $runRoot "server.cfg"
@"
hostname = "WMP Full Audit";
password = "wmpqa";
passwordAdmin = "wmpqa";
maxPlayers = 5;
persistent = 1;
BattlEye = 0;
verifySignatures = 0;
allowedFilePatching = 2;
class Missions
{
    class FullAudit
    {
        template = "WMP_Full_Arma_Audit.VR";
        difficulty = "Regular";
    };
};
"@ | Set-Content -LiteralPath $serverConfig -Encoding ASCII

$serverArgs = @(
    "-noBattlEye", "-noSound", "-noPause", "-autoInit",
    "-port=$Port", "-config=$serverConfig", "-profiles=$serverProfile", "-name=WMPAuditServer"
)
if ($null -ne $modArgument) { $serverArgs += $modArgument }
$started = Get-Date
$server = Start-Process -FilePath $serverExe -ArgumentList $serverArgs -PassThru -WindowStyle Hidden
$processes = @($server)

try {
    $serverReadyDeadline = (Get-Date).AddSeconds(90)
    $serverReady = $false
    while ((Get-Date) -lt $serverReadyDeadline -and -not $server.HasExited) {
        Start-Sleep -Milliseconds 500
        $serverRpt = Get-ChildItem -LiteralPath $serverProfile -Filter "*.rpt" -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($null -ne $serverRpt) {
            $missionLoadError = Select-String -LiteralPath $serverRpt.FullName -Pattern "You cannot play/edit this mission|Mission .* was deleted|Missing addons detected" | Select-Object -Last 1
            if ($null -ne $missionLoadError -and $missionLoadError.Line -notmatch "a3_characters_f\s*$") {
                throw ("Arma rejected the audit mission before startup: " + $missionLoadError.Line)
            }
            $serverReady = [bool](Select-String -LiteralPath $serverRpt.FullName -Pattern "Game started|Mission world: VR|WMP FULL AUDIT BOOT:" -Quiet)
            if ($serverReady) { break }
        }
    }
    if (-not $serverReady) { throw "Dedicated audit server did not start the VR mission." }

    for ($index = 1; $index -le $Clients; $index++) {
        $clientProfile = Join-Path $runRoot "client$index"
        New-Item -ItemType Directory -Path $clientProfile -Force | Out-Null
        $clientArgs = @(
            "-noBattlEye", "-noSplash", "-skipIntro", "-world=empty", "-showScriptErrors",
            "-window", "-x=$ResolutionWidth", "-y=$ResolutionHeight", "-noPause", "-connect=localhost", "-port=$Port",
            "-password=wmpqa", "-profiles=$clientProfile", "-name=WMPAudit$index"
        )
        if ($null -ne $modArgument) { $clientArgs += $modArgument }
        $client = Start-Process -FilePath $clientExe -ArgumentList $clientArgs -PassThru
        $processes += $client
        Start-Sleep -Seconds 2
    }

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $serverComplete = $false
    $completedClients = 0
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 1
        $serverRpt = Get-ChildItem -LiteralPath $serverProfile -Filter "*.rpt" -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($null -ne $serverRpt) {
            $serverComplete = [bool](Select-String -LiteralPath $serverRpt.FullName -Pattern "WMP FULL AUDIT COMPLETE:" -Quiet)
        }
        $completedClients = 0
        for ($index = 1; $index -le $Clients; $index++) {
            $clientProfile = Join-Path $runRoot "client$index"
            $clientRpt = Get-ChildItem -LiteralPath $clientProfile -Filter "*.rpt" -Recurse -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($null -ne $clientRpt -and (Select-String -LiteralPath $clientRpt.FullName -Pattern "WMP FULL AUDIT COMPLETE:" -Quiet)) {
                $completedClients++
            }
        }
        if ($serverComplete -and $completedClients -eq $Clients) { break }
    }
    if (-not $serverComplete -or $completedClients -ne $Clients) {
        throw "Dedicated audit timed out: serverComplete=$serverComplete clients=$completedClients/$Clients"
    }

    $rpts = Get-ChildItem -LiteralPath $runRoot -Filter "*.rpt" -Recurse
    $errorPatterns = "Error in expression|Error position:|Undefined variable|Warning Message: Script .* not found"
    $runtimeErrors = $rpts | Select-String -Pattern $errorPatterns
    if ($runtimeErrors) {
        $runtimeErrors | ForEach-Object { Write-Output ("RUNTIME ERROR: " + $_.Path + ":" + $_.LineNumber + " " + $_.Line) }
        throw "Dedicated audit RPT contains script errors."
    }
    foreach ($rpt in $rpts) {
        $safeName = ($rpt.Directory.Name + "-" + $rpt.BaseName) -replace "[^A-Za-z0-9_.-]", "_"
        $json = Join-Path $runRoot "$safeName.json"
        $markdown = Join-Path $runRoot "$safeName.md"
        & $PythonExecutable (Join-Path $PSScriptRoot "parse_full_arma_audit.py") $rpt.FullName --json $json --markdown $markdown
        if ($LASTEXITCODE -ne 0) { throw "Structured failures found in $($rpt.FullName)" }
    }
    Write-Output "Dedicated audit passed: suite=$Suite profile=$ModProfile clients=$Clients evidence=$runRoot"
}
finally {
    if (-not $LeaveClientsOpen) {
        foreach ($process in $processes) {
            if ($null -ne $process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
        }
    }
}
