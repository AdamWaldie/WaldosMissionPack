param(
    [ValidateSet("all", "core", "economy", "ew", "party", "interactions")]
    [string]$Suite = "all",
    [ValidateSet("core", "acre", "tfar")]
    [string]$ModProfile = "acre",
    [ValidateSet("Manual", "Automated")]
    [string]$Mode = "Manual",
    [int]$Port = 24132,
    [ValidateRange(1280, 3840)]
    [int]$ResolutionWidth = 2560,
    [ValidateRange(720, 2160)]
    [int]$ResolutionHeight = 1440,
    [switch]$ExcludePersistenceMod,
    [string]$PythonExecutable = ""
)

$ErrorActionPreference = "Stop"
if ($ModProfile -ne "acre") {
    throw "The canonical interactive full-pack audit currently uses the ACRE profile. Use launch_full_arma_dedicated_audit.ps1 for automated core/TFAR coverage."
}

$launcher = Join-Path $PSScriptRoot "launch_pr_review_audit.ps1"
$arguments = @{
    Suite = $Suite
    Mode = $Mode
    Port = $Port
    ResolutionWidth = $ResolutionWidth
    ResolutionHeight = $ResolutionHeight
}
if ($ExcludePersistenceMod) { $arguments.ExcludePersistenceMod = $true }
if (-not [string]::IsNullOrWhiteSpace($PythonExecutable)) { $arguments.PythonExecutable = $PythonExecutable }

Write-Output "Launching the canonical version-12 full-pack audit mission. Eden is not used."
& $launcher @arguments
