<#
 * Author: WaldoTheWarfighter
 * Launches the canonical dedicated full-pack audit in its ThemeGallery mode, enters the first
 * playable slot, and captures the real Arma window when each RPT frame-ready marker appears.
 * The resulting cropped PNGs show the production WMP notification stack and are suitable for the
 * wiki theme chooser. Six full-screen PNGs prove a real three-card stack in every supported
 * placement, and three runtime-evidence PNGs capture the player settings screens. The script owns
 * and closes only the client/server processes from this run.
 *
 * Parameters:
 * OutputDirectory: destination for the twenty theme and six placement PNG files.
 * ResolutionWidth/ResolutionHeight: connected audit client dimensions (default 3840x2160).
 * KeepRunning: leave the audit client and server open after capture for manual inspection.
 *
 * Example:
 * powershell -ExecutionPolicy Bypass -File .\releaseVerificationAndDeployment\capture_ui_theme_gallery.ps1
 * Current caller: documentation maintainers refreshing wiki theme previews.
 #>
param(
    [string]$OutputDirectory = "..\wiki\assets\ui-themes",
    [int]$ResolutionWidth = 3840,
    [int]$ResolutionHeight = 2160,
    [switch]$KeepRunning
)

$ErrorActionPreference = "Stop"
$launcher = Join-Path $PSScriptRoot "launch_pr_review_audit.ps1"
$capture = Join-Path $PSScriptRoot "capture_interaction_ui.ps1"
$repoRoot = Split-Path -Parent $PSScriptRoot
$absoluteOutput = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    [System.IO.Path]::GetFullPath($OutputDirectory)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $OutputDirectory))
}
[System.IO.Directory]::CreateDirectory($absoluteOutput) | Out-Null

$themes = @(
    "GRIMDARK", "ATOMIC_AGE", "WASTELAND", "PMC", "RETRO_COMMAND", "DIESELPUNK",
    "MERCENARY", "PROPAGANDA", "DEFAULT", "WW2", "VIETNAM", "SCIFI", "PARCHMENT",
    "MINIMAL", "NAVAL", "DESERT_STORM", "INDUSTRIAL", "EASTERN_BLOC", "INTELLIGENCE",
    "EMERGENCY"
)

if (-not ("WmpThemeGalleryInput" -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class WmpThemeGalleryInput {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extraInfo);
    [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr dpiContext);
}
"@
}
[WmpThemeGalleryInput]::SetProcessDpiAwarenessContext([IntPtr](-4)) | Out-Null
Add-Type -AssemblyName System.Drawing

function Invoke-ArmaRelativeClick {
    param([System.Diagnostics.Process]$Process, [double]$X, [double]$Y)
    $rect = $null
    $handle = [IntPtr]::Zero
    $boundsDeadline = (Get-Date).AddSeconds(10)
    do {
        $Process.Refresh()
        $handle = $Process.MainWindowHandle
        if ($handle -ne [IntPtr]::Zero) {
            $candidate = New-Object WmpThemeGalleryInput+RECT
            if ([WmpThemeGalleryInput]::GetWindowRect($handle, [ref]$candidate)) {
                $rect = $candidate
                break
            }
        }
        Start-Sleep -Milliseconds 250
    } while ((Get-Date) -lt $boundsDeadline -and -not $Process.HasExited)
    if ($null -eq $rect) {
        throw "Could not read the current Arma window bounds."
    }
    [WmpThemeGalleryInput]::SetForegroundWindow($handle) | Out-Null
    $screenX = $rect.Left + [int](($rect.Right - $rect.Left) * $X)
    $screenY = $rect.Top + [int](($rect.Bottom - $rect.Top) * $Y)
    [WmpThemeGalleryInput]::SetCursorPos($screenX, $screenY) | Out-Null
    [WmpThemeGalleryInput]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero)
    [WmpThemeGalleryInput]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
}

function Save-ThemeCrop {
    param([string]$Source, [string]$Destination)
    $image = [System.Drawing.Image]::FromFile($Source)
    try {
        $crop = New-Object System.Drawing.Rectangle(
            [int]($image.Width * 0.57), [int]($image.Height * 0.025),
            [int]($image.Width * 0.41), [int]($image.Height * 0.46)
        )
        $bitmap = New-Object System.Drawing.Bitmap $crop.Width, $crop.Height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.DrawImage($image, 0, 0, $crop, [System.Drawing.GraphicsUnit]::Pixel)
            $bitmap.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $graphics.Dispose()
            $bitmap.Dispose()
        }
    }
    finally {
        $image.Dispose()
    }
}

$client = $null
$server = $null
try {
    & $launcher -Suite core -Mode ThemeGallery -ResolutionWidth $ResolutionWidth -ResolutionHeight $ResolutionHeight
    if ($LASTEXITCODE -ne 0) { throw "The full-pack theme-gallery audit did not launch." }

    $runtime = Get-ChildItem -LiteralPath (Join-Path $repoRoot ".qa\pr-review-audit") -Directory -Filter "runtime-*" |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -eq $runtime) { throw "The audit launcher did not create a runtime evidence directory." }
    $server = Get-Process arma3server_x64 -ErrorAction Stop | Sort-Object StartTime -Descending | Select-Object -First 1

    $windowDeadline = (Get-Date).AddSeconds(60)
    do {
        Start-Sleep -Milliseconds 500
        $client = Get-Process arma3_x64 -ErrorAction SilentlyContinue | Sort-Object StartTime -Descending | Select-Object -First 1
    } while (($null -eq $client -or $client.MainWindowHandle -eq 0) -and (Get-Date) -lt $windowDeadline)
    if ($null -eq $client -or $client.MainWindowHandle -eq 0) { throw "The Arma audit client did not open a visible window." }

    Start-Sleep -Seconds 12
    Invoke-ArmaRelativeClick -Process $client -X 0.13 -Y 0.215
    Start-Sleep -Seconds 8

    $galleryDeadline = (Get-Date).AddSeconds(90)
    $rpt = $null
    do {
        Invoke-ArmaRelativeClick -Process $client -X 0.95 -Y 0.965
        Start-Sleep -Seconds 2
        $rpt = Get-ChildItem -LiteralPath (Join-Path $runtime.FullName "client") -Filter "*.rpt" -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $started = $null -ne $rpt -and (Select-String -LiteralPath $rpt.FullName -Pattern "WMP UI THEME GALLERY START" -Quiet)
    } while (-not $started -and (Get-Date) -lt $galleryDeadline -and -not $client.HasExited)
    if (-not $started) { throw "The audit client did not enter the VR mission and start the theme gallery." }

    foreach ($theme in $themes) {
        $framePattern = "WMP UI THEME GALLERY FRAME READY: theme=$theme "
        $frameDeadline = (Get-Date).AddSeconds(30)
        while (-not (Select-String -LiteralPath $rpt.FullName -SimpleMatch $framePattern -Quiet)) {
            if ((Get-Date) -ge $frameDeadline -or $client.HasExited) {
                throw "Timed out waiting for the $theme theme frame."
            }
            Start-Sleep -Milliseconds 150
        }

        $stem = $theme.ToLowerInvariant().Replace("_", "-")
        $fullPath = Join-Path $runtime.FullName "$stem-full.png"
        $outputPath = Join-Path $absoluteOutput "$stem.png"
        $client.Refresh()
        if ($client.MainWindowHandle -eq 0) { throw "The Arma window disappeared before the $theme capture." }
        [WmpThemeGalleryInput]::SetForegroundWindow($client.MainWindowHandle) | Out-Null
        Start-Sleep -Milliseconds 200
        & $capture -OutputPath $fullPath | Out-Null
        Save-ThemeCrop -Source $fullPath -Destination $outputPath
        Remove-Item -LiteralPath $fullPath
        Write-Output "Captured $theme -> $outputPath"
    }

    $placements = @("TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT")
    foreach ($placement in $placements) {
        $framePattern = "WMP UI NOTIFICATION POSITION FRAME READY: placement=$placement count=3"
        $frameDeadline = (Get-Date).AddSeconds(30)
        while (-not (Select-String -LiteralPath $rpt.FullName -SimpleMatch $framePattern -Quiet)) {
            if ((Get-Date) -ge $frameDeadline -or $client.HasExited) {
                throw "Timed out waiting for the $placement three-card position frame."
            }
            Start-Sleep -Milliseconds 150
        }
        $stem = $placement.ToLowerInvariant().Replace("_", "-")
        $positionPath = Join-Path $absoluteOutput "notification-position-$stem.png"
        $client.Refresh()
        if ($client.MainWindowHandle -eq 0) { throw "The Arma window disappeared before the $placement position capture." }
        [WmpThemeGalleryInput]::SetForegroundWindow($client.MainWindowHandle) | Out-Null
        Start-Sleep -Milliseconds 200
        & $capture -OutputPath $positionPath | Out-Null
        Write-Output "Captured three-card $placement stack -> $positionPath"
    }

    foreach ($screen in @("NOTIFICATION", "HUD", "ACCESSIBILITY")) {
        $framePattern = "WMP UI SETTINGS FRAME READY: screen=$screen"
        $frameDeadline = (Get-Date).AddSeconds(30)
        while (-not (Select-String -LiteralPath $rpt.FullName -SimpleMatch $framePattern -Quiet)) {
            if ((Get-Date) -ge $frameDeadline -or $client.HasExited) {
                throw "Timed out waiting for the $screen settings frame."
            }
            Start-Sleep -Milliseconds 150
        }
        $settingsPath = Join-Path $runtime.FullName ("ui-settings-" + $screen.ToLowerInvariant() + ".png")
        $client.Refresh()
        [WmpThemeGalleryInput]::SetForegroundWindow($client.MainWindowHandle) | Out-Null
        Start-Sleep -Milliseconds 200
        & $capture -OutputPath $settingsPath | Out-Null
        Write-Output "Captured $screen settings -> $settingsPath"
    }

    if (-not (Select-String -LiteralPath $rpt.FullName -Pattern "WMP UI THEME GALLERY COMPLETE: count=20" -Quiet)) {
        Start-Sleep -Seconds 5
    }
    Write-Output "Captured all twenty themes, six notification positions and three settings screens."
}
finally {
    if (-not $KeepRunning) {
        if ($null -ne $client -and -not $client.HasExited) {
            $client.CloseMainWindow() | Out-Null
            if (-not $client.WaitForExit(10000)) { Stop-Process -Id $client.Id -Force -ErrorAction SilentlyContinue }
        }
        if ($null -ne $server -and -not $server.HasExited) {
            Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
        }
    }
}
