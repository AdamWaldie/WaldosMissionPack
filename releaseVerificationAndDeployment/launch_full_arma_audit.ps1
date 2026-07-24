param(
    [ValidateSet("all", "core", "economy", "ew", "party", "interactions")]
    [string]$Suite = "all",
    [ValidateSet("none", "core", "acre", "tfar")]
    [string]$ModProfile = "none",
    [int]$TimeoutSeconds = 180,
    [string]$PythonExecutable = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$armaRoot = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3").main
$armaExe = Join-Path $armaRoot "arma3_x64.exe"
$missionRoot = Join-Path $armaRoot "Missions\WMP_Full_Arma_Audit.VR"
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
& $PythonExecutable (Join-Path $PSScriptRoot "build_full_arma_audit.py") --destination $missionRoot --suite $Suite
if ($LASTEXITCODE -ne 0) { throw "Full audit mission assembly failed." }

$modNames = switch ($ModProfile) {
    "core" { @("@CBA_A3", "@ace", "@Zeus Enhanced", "@ACRE2") }
    "acre" { @("@CBA_A3", "@ace", "@Zeus Enhanced", "@ACRE2") }
    "tfar" { @("@CBA_A3", "@ace", "@Zeus Enhanced", "@Task Force Arrowhead Radio (BETA!!!)") }
    default { @() }
}
$mods = @()
foreach ($name in $modNames) {
    $path = Join-Path (Join-Path $armaRoot "!Workshop") $name
    if (-not (Test-Path -LiteralPath $path)) { throw "Required audit mod is not installed: $name" }
    $mods += $path
}

$qaRoot = "\Missions\WMP_Full_Arma_Audit.VR\"
$bootstrap = $qaRoot + "scriptedBootstrap.sqf"
$scriptedCode = 'Waldo_QA_Root="' + $qaRoot + '";[] execVM "' + $bootstrap + '";'
$codes = ($scriptedCode.ToCharArray() | ForEach-Object { [int]$_ }) -join ","
$arguments = @("-noBattlEye", "-noSplash", "-skipIntro", "-world=empty", "-showScriptErrors", "-filePatching", "-window", "-noPause")
if ($mods.Count -gt 0) { $arguments += '-mod="' + ($mods -join ';') + '"' }
$arguments += "-init=playScriptedMission[toString[86,82],compile(toString[$codes]),configNull,true]"
$started = Get-Date
$process = Start-Process -FilePath $armaExe -ArgumentList $arguments -PassThru -WindowStyle Hidden

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$rpt = $null
$complete = $false
while ((Get-Date) -lt $deadline -and -not $process.HasExited) {
    Start-Sleep -Milliseconds 500
    $rpt = Get-ChildItem (Join-Path $env:LOCALAPPDATA "Arma 3\arma3_x64_*.rpt") -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -ge $started.AddSeconds(-2) } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -ne $rpt) {
        $complete = [bool](Select-String -LiteralPath $rpt.FullName -Pattern "WMP FULL AUDIT COMPLETE:" -Quiet)
        if ($complete) { break }
    }
}
if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
if (-not $complete -or $null -eq $rpt) { throw "Arma full audit did not emit a completion record within $TimeoutSeconds seconds." }

$output = Join-Path $repoRoot ".qa\full-arma-audit"
New-Item -ItemType Directory -Path $output -Force | Out-Null
$json = Join-Path $output "$Suite-$ModProfile.json"
$markdown = Join-Path $output "$Suite-$ModProfile.md"
& $python.Source (Join-Path $PSScriptRoot "parse_full_arma_audit.py") $rpt.FullName --json $json --markdown $markdown
if ($LASTEXITCODE -ne 0) { throw "Arma full audit reported failures. See $markdown" }
Write-Output $markdown
