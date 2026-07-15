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
            $isPurpleFringe = ($c.R -gt 120 -and $c.B -gt 120 -and $c.G -lt 80)
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
        $g.Clear([Drawing.Color]::FromArgb(0, 0, 0, 0))
        $g.DrawImage($out, 0, 0, $TargetSize, $TargetSize)
        $g.Dispose()
        $out.Dispose()
        $out = $scaled
    }

    $out.Save($OutputPath, [Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose()
}

function Resize-Width([string]$InputPath, [string]$OutputPath, [int]$TargetW) {
    $src = [Drawing.Image]::FromFile($InputPath)
    $ratio = $TargetW / $src.Width
    $targetH = [int][math]::Round($src.Height * $ratio)
    $out = New-Object Drawing.Bitmap $TargetW, $targetH, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($out)
    $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.Clear([Drawing.Color]::FromArgb(0, 0, 0, 0))
    $g.DrawImage($src, 0, 0, $TargetW, $targetH)
    $g.Dispose()
    $src.Dispose()
    $out.Save($OutputPath, [Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose()
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$assets = Join-Path $env:USERPROFILE ".cursor\projects\c-Users-Basant-Projects-scratch-platformer\assets"
$outDir = Join-Path $root "sprites\flappy_world"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$items = @(
    @{ src = "obstacle_wardrobe.png"; dst = "wardrobe.png";      smallW = 128 },
    @{ src = "ground_blanket.png";    dst = "blanket_ground.png"; smallW = 480 },
    @{ src = "obstacle_tv.png";       dst = "tv.png";             smallW = 160 }
)

foreach ($item in $items) {
    $input = Join-Path $assets $item.src
    if (-not (Test-Path $input)) {
        Write-Warning "Missing: $input"
        continue
    }
    $tmp = Join-Path $outDir ("tmp_" + $item.dst)
    $output = Join-Path $outDir $item.dst
    Remove-MagentaBackground $input $tmp
    Move-Item $tmp $output -Force
    $img = [Drawing.Image]::FromFile($output)
    Write-Host "Created: $output ($($img.Width)x$($img.Height))"
    $img.Dispose()

    $smallName = [IO.Path]::GetFileNameWithoutExtension($item.dst) + "_small.png"
    $smallOut = Join-Path $outDir $smallName
    Resize-Width $output $smallOut $item.smallW
    $small = [Drawing.Image]::FromFile($smallOut)
    Write-Host "Created: $smallOut ($($small.Width)x$($small.Height))"
    $small.Dispose()
}

Write-Host "Done."
