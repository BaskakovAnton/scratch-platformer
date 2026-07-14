$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Test-BackgroundColor([System.Drawing.Color]$c) {
    if ($c.A -lt 20) { return $true }
    $avg = ($c.R + $c.G + $c.B) / 3.0
    $maxDiff = [Math]::Max([Math]::Abs($c.R - $c.G), [Math]::Max([Math]::Abs($c.G - $c.B), [Math]::Abs($c.R - $c.B)))
    if ($maxDiff -le 18 -and $avg -ge 175) { return $true }
    return $false
}

function Remove-Background([string]$InputPath, [string]$OutputPath) {
    $src = [Drawing.Image]::FromFile($InputPath)
    $srcBmp = New-Object Drawing.Bitmap $src
    $src.Dispose()

    $w = $srcBmp.Width
    $h = $srcBmp.Height
    $out = New-Object Drawing.Bitmap $w, $h, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($out)
    $g.Clear([Drawing.Color]::FromArgb(0, 0, 0, 0))
    $g.Dispose()

    $visited = New-Object 'System.Collections.Generic.HashSet[int]'
    $queue = New-Object System.Collections.Generic.Queue[object]

    function Enqueue([int]$x, [int]$y) {
        if ($x -lt 0 -or $y -lt 0 -or $x -ge $w -or $y -ge $h) { return }
        $key = ($y * $w) + $x
        if ($visited.Contains($key)) { return }
        $color = $srcBmp.GetPixel($x, $y)
        if (-not (Test-BackgroundColor $color)) { return }
        [void]$visited.Add($key)
        $queue.Enqueue(@($x, $y))
    }

    for ($x = 0; $x -lt $w; $x++) {
        Enqueue $x 0
        Enqueue $x ($h - 1)
    }
    for ($y = 0; $y -lt $h; $y++) {
        Enqueue 0 $y
        Enqueue ($w - 1) $y
    }

    while ($queue.Count -gt 0) {
        $p = $queue.Dequeue()
        $x = $p[0]
        $y = $p[1]
        Enqueue ($x - 1) $y
        Enqueue ($x + 1) $y
        Enqueue $x ($y - 1)
        Enqueue $x ($y + 1)
    }

    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            $key = ($y * $w) + $x
            $srcColor = $srcBmp.GetPixel($x, $y)
            if ($visited.Contains($key)) {
                $out.SetPixel($x, $y, [Drawing.Color]::FromArgb(0, 0, 0, 0))
            } else {
                $out.SetPixel($x, $y, [Drawing.Color]::FromArgb(255, $srcColor.R, $srcColor.G, $srcColor.B))
            }
        }
    }

    $srcBmp.Dispose()
    $out.Save($OutputPath, [Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose()
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$targets = @(
    (Join-Path $root "sprites\hero.png"),
    (Join-Path $root "sprites\house.png"),
    (Join-Path $root "sprites\platform_ground.png"),
    (Join-Path $root "sprites\rhinoceros.png"),
    (Join-Path $root "sprites_hd\hero.png"),
    (Join-Path $root "sprites_hd\house.png"),
    (Join-Path $root "sprites_hd\platform_ground.png"),
    (Join-Path $root "sprites_hd\rhinoceros.png")
) | Where-Object { Test-Path $_ }

foreach ($path in $targets) {
    $tmp = "$path.tmp.png"
    Remove-Background $path $tmp
    Move-Item $tmp $path -Force
    Write-Host "Fixed: $path"
}
