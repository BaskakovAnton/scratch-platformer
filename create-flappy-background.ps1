$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$outDir = Join-Path $root "backgrounds"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$out = Join-Path $outDir "flappy_room.png"

$w = 480
$h = 360
$bmp = New-Object Drawing.Bitmap $w, $h
$g = [Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias

# walls
$g.Clear([Drawing.Color]::FromArgb(255, 185, 185, 190))

# ceiling
$g.FillRectangle([Drawing.Brushes]::White, 0, 0, $w, 40)

# ceiling light panels
$light = [Drawing.Color]::FromArgb(255, 245, 250, 255)
$g.FillRectangle((New-Object Drawing.SolidBrush $light), 130, 8, 50, 22)
$g.FillRectangle((New-Object Drawing.SolidBrush $light), 190, 8, 50, 22)
$g.FillRectangle((New-Object Drawing.SolidBrush $light), 250, 8, 50, 22)
$g.FillRectangle((New-Object Drawing.SolidBrush $light), 310, 8, 50, 22)

# parquet floor
$wood1 = [Drawing.Color]::FromArgb(255, 160, 115, 70)
$wood2 = [Drawing.Color]::FromArgb(255, 130, 90, 55)
for ($y = 250; $y -lt $h; $y += 12) {
    $brush = if (([int]($y / 12) % 2) -eq 0) { New-Object Drawing.SolidBrush $wood1 } else { New-Object Drawing.SolidBrush $wood2 }
    $g.FillRectangle($brush, 0, $y, $w, 12)
}

# dresser hint on right
$g.FillRectangle((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 175, 125, 80))), 360, 210, 120, 45)

# wardrobe hint on left
$g.FillRectangle([Drawing.Brushes]::DimGray, 0, 60, 90, 200)
$g.FillRectangle((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 175, 125, 80))), 0, 150, 90, 18)

# door center
$g.FillRectangle([Drawing.Brushes]::White, 205, 95, 70, 160)
$g.DrawRectangle([Drawing.Pens]::SaddleBrown, 205, 95, 70, 160)

$g.Dispose()
$bmp.Save($out, [Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Created: $out"
