param([string]$OutputDirectory = ".\.qa\documentation-gallery")
$ErrorActionPreference = "Stop"
$launcher = Join-Path $PSScriptRoot "launch_documentation_capture_batch.ps1"
$output = [System.IO.Path]::GetFullPath($OutputDirectory)
[System.IO.Directory]::CreateDirectory($output) | Out-Null
$cases = @("economy-resources", "economy-resource-config", "economy-research", "economy-build", "economy-purchases", "economy-builder", "economy-drop-point", "safestart-countdown", "endex")
& $launcher -Cases $cases -OutputDirectory $output
Write-Output "Captured $($cases.Count) documentation states in $output"
