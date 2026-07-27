param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"
if (-not ("WmpWindowCapture" -as [type])) {
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class WmpWindowCapture {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
    [DllImport("user32.dll")]
    public static extern bool SetProcessDpiAwarenessContext(IntPtr dpiContext);
}
"@
}
# PrintWindow renders Arma in physical pixels. Make this capture process
# per-monitor-DPI-aware before asking Windows for the target bounds, otherwise a
# 150%/200% desktop scale allocates a smaller bitmap and crops the right/bottom.
[WmpWindowCapture]::SetProcessDpiAwarenessContext([IntPtr](-4)) | Out-Null
Add-Type -AssemblyName System.Drawing

$process = Get-Process arma3_x64 -ErrorAction Stop | Sort-Object Id -Descending | Select-Object -First 1
if ($process.MainWindowHandle -eq 0) {
    throw "Arma 3 has no visible main window."
}
[WmpWindowCapture]::ShowWindowAsync($process.MainWindowHandle, 9) | Out-Null
[WmpWindowCapture]::SetForegroundWindow($process.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 350
$rect = New-Object WmpWindowCapture+RECT
if (-not [WmpWindowCapture]::GetWindowRect($process.MainWindowHandle, [ref]$rect)) {
    throw "Could not read the Arma 3 window bounds."
}
$width = $rect.Right - $rect.Left
$height = $rect.Bottom - $rect.Top
[WmpWindowCapture]::SetCursorPos($rect.Left + 8, $rect.Top + 8) | Out-Null
Start-Sleep -Milliseconds 1200
$bitmap = New-Object System.Drawing.Bitmap $width, $height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
try {
    $hdc = $graphics.GetHdc()
    try {
        if (-not [WmpWindowCapture]::PrintWindow($process.MainWindowHandle, $hdc, 2)) {
            throw "Could not capture the Arma 3 window."
        }
    }
    finally {
        $graphics.ReleaseHdc($hdc)
    }
    $absolute = [System.IO.Path]::GetFullPath($OutputPath)
    $directory = [System.IO.Path]::GetDirectoryName($absolute)
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    $bitmap.Save($absolute, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output $absolute
}
finally {
    $graphics.Dispose()
    $bitmap.Dispose()
}
