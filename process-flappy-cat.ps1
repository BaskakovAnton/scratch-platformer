$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Remove-MagentaBackground([string]$InputPath, [string]$OutputPath, [int]$TargetSize = 0) {
    $src = [Drawing.Image]::FromFile($InputPath)
    $srcBmp = New-Object Drawing.Bitmap $src
    $src.Dispose()

    $w = $srcBmp.Width
    $h = $srcBmp.Height
    $out = New-Object Drawing.Bitmap $w, $h, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)

    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            $c = $srcBmp.GetPixel($x, $y)
            $isMagenta = ($c.R -gt 150 -and $c.B -gt 150 -and $c.G -lt 140)
            $isNearWhite = ($c.R -gt 235 -and $c.G -gt 235 -and $c.B -gt 235)
            $isPurpleFringe = ($c.R -gt 120 -and $c.B -gt 120 -and $c.G -lt 80 -and $c.A -gt 0)
            if ($isMagenta -or $isNearWhite -or $isPurpleFringe) {
                $out.SetPixel($x, $y, [Drawing.Color]::FromArgb(0, 0, 0, 0))
            } else {
                $out.SetPixel($x, $y, [Drawing.Color]::FromArgb(255, $c.R, $c.G, $c.B))
            }
        }
    }

    $srcBmp.Dispose()

    if ($TargetSize -gt 0 -and ($w -ne $TargetSize -or $h -ne $TargetSize)) {
        $scaled = New-Object Drawing.Bitmap $TargetSize, $TargetSize, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [Drawing.Graphics]::FromImage($scaled)
        $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.Clear([Drawing.Color]::FromArgb(0, 0, 0, 0))
        $g.DrawImage($out, 0, 0, $TargetSize, $TargetSize)
        $g.Dispose()
        $out.Dispose()
        $out = $scaled
    }

    $out.Save($OutputPath, [Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose()
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$assets = Join-Path $env:USERPROFILE ".cursor\projects\c-Users-Basant-Projects-scratch-platformer\assets"
$outDir = Join-Path $root "sprites\flappy_cat"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$frames = @(
    @{ src = "flappy_cat_wing_up.png";   dst = "wing_up.png" },
    @{ src = "flappy_cat_wing_down.png"; dst = "wing_down.png" },
    @{ src = "flappy_cat_dead.png";      dst = "dead.png" }
)

foreach ($frame in $frames) {
    $input = Join-Path $assets $frame.src
    if (-not (Test-Path $input)) {
        Write-Warning "Missing: $input"
        continue
    }
    $output = Join-Path $outDir $frame.dst
    Remove-MagentaBackground $input $output
    $img = [Drawing.Image]::FromFile($output)
    Write-Host "Created: $output ($($img.Width)x$($img.Height))"
    $img.Dispose()

    $smallName = [IO.Path]::GetFileNameWithoutExtension($frame.dst) + "_256.png"
    $smallOut = Join-Path $outDir $smallName
    Remove-MagentaBackground $input $smallOut 256
    $small = [Drawing.Image]::FromFile($smallOut)
    Write-Host "Created: $smallOut ($($small.Width)x$($small.Height))"
    $small.Dispose()
}

Write-Host "Done."
