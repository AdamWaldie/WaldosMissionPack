param(
    [string]$OutputDirectory = ".\.qa\interaction-ui-gallery",
    [ValidateSet("easy", "standard", "hard", "expert")]
    [string]$Difficulty = "standard",
    [ValidateSet("Briefing", "Active", "Both")]
    [string]$State = "Both"
)

$ErrorActionPreference = "Stop"
$launcher = Join-Path $PSScriptRoot "launch_interaction_ui_qa.ps1"
$absoluteOutput = [System.IO.Path]::GetFullPath($OutputDirectory)
[System.IO.Directory]::CreateDirectory($absoluteOutput) | Out-Null
$challenges = @("wirecut", "minesweeper", "keypad", "lockpick", "circuit", "repair", "radiotune", "pressure", "sequence", "commandinput")
$modes = switch ($State) {
    "Briefing" { @("Interactive") }
    "Active" { @("Active") }
    default { @("Interactive", "Active") }
}

foreach ($challenge in $challenges) {
    foreach ($mode in $modes) {
        $stateName = if ($mode -eq "Interactive") { "briefing" } else { "active" }
        $outputPath = Join-Path $absoluteOutput "$challenge-$Difficulty-$stateName.png"
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File $launcher `
            -Mode $mode `
            -Challenge $challenge `
            -Difficulty $Difficulty `
            -CaptureScreenshot `
            -ScreenshotPath $outputPath `
            -CloseAfterCapture
        if ($LASTEXITCODE -ne 0) {
            throw "Visual QA capture failed for $challenge/$Difficulty/$stateName."
        }
    }
}

Write-Output "Captured $($challenges.Count * $modes.Count) Arma UI screenshots in $absoluteOutput"
