$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$template = Join-Path $root "flappy-busya.template.json"
$outSb3 = Join-Path $root "flappy-busya.sb3"
$temp = Join-Path $env:TEMP ("flappy-busya-" + [guid]::NewGuid().ToString())

& (Join-Path $root "create-flappy-background.ps1")

function Flip-Vertical([string]$InputPath, [string]$OutputPath) {
    $src = [Drawing.Image]::FromFile($InputPath)
    $out = New-Object Drawing.Bitmap $src.Width, $src.Height
    $g = [Drawing.Graphics]::FromImage($out)
    $g.DrawImage($src, 0, $src.Height, $src.Width, -$src.Height)
    $g.Dispose()
    $src.Dispose()
    $out.Save($OutputPath, [Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose()
}

$wardrobeTop = Join-Path $root "sprites\flappy_world\wardrobe_top_small.png"
Flip-Vertical (Join-Path $root "sprites\flappy_world\wardrobe_small.png") $wardrobeTop

New-Item -ItemType Directory -Force -Path $temp | Out-Null

function Get-ImageSize([string]$path) {
    $img = [Drawing.Image]::FromFile($path)
    try { return @{ W = $img.Width; H = $img.Height } }
    finally { $img.Dispose() }
}

function Import-Asset([string]$sourcePath) {
    if (-not (Test-Path $sourcePath)) { throw "Asset not found: $sourcePath" }
    $bytes = [IO.File]::ReadAllBytes($sourcePath)
    $md5 = [BitConverter]::ToString(
        (New-Object Security.Cryptography.MD5CryptoServiceProvider).ComputeHash($bytes)
    ).Replace("-", "").ToLower()
    $ext = [IO.Path]::GetExtension($sourcePath).TrimStart('.').ToLower()
    $md5ext = "$md5.$ext"
    Copy-Item $sourcePath (Join-Path $temp $md5ext) -Force
    $size = Get-ImageSize $sourcePath
    return @{
        md5 = $md5
        md5ext = $md5ext
        cx = [int][math]::Round($size.W / 2)
        cy = [int][math]::Round($size.H / 2)
        w = $size.W
        h = $size.H
    }
}

$bg = Import-Asset (Join-Path $root "backgrounds\flappy_room.png")
$wingUp = Import-Asset (Join-Path $root "sprites\flappy_cat\wing_up_256.png")
$wingDown = Import-Asset (Join-Path $root "sprites\flappy_cat\wing_down_256.png")
$dead = Import-Asset (Join-Path $root "sprites\flappy_cat\dead_256.png")
$wardrobe = Import-Asset (Join-Path $root "sprites\flappy_world\wardrobe_small.png")
$wardrobeTopAsset = Import-Asset $wardrobeTop
$blanket = Import-Asset (Join-Path $root "sprites\flappy_world\blanket_ground_small.png")
$tv = Import-Asset (Join-Path $root "sprites\flappy_world\tv_small.png")

$json = Get-Content $template -Raw -Encoding UTF8
$replacements = @{
    '{{BG_MD5}}' = $bg.md5; '{{BG_MD5EXT}}' = $bg.md5ext
    '{{WING_UP_MD5}}' = $wingUp.md5; '{{WING_UP_MD5EXT}}' = $wingUp.md5ext
    '{{WING_DOWN_MD5}}' = $wingDown.md5; '{{WING_DOWN_MD5EXT}}' = $wingDown.md5ext
    '{{DEAD_MD5}}' = $dead.md5; '{{DEAD_MD5EXT}}' = $dead.md5ext
    '{{WARDROBE_MD5}}' = $wardrobe.md5; '{{WARDROBE_MD5EXT}}' = $wardrobe.md5ext
    '{{WARDROBE_TOP_MD5}}' = $wardrobeTopAsset.md5; '{{WARDROBE_TOP_MD5EXT}}' = $wardrobeTopAsset.md5ext
    '{{BLANKET_MD5}}' = $blanket.md5; '{{BLANKET_MD5EXT}}' = $blanket.md5ext
    '{{TV_MD5}}' = $tv.md5; '{{TV_MD5EXT}}' = $tv.md5ext
    '{{WING_CX}}' = $wingUp.cx; '{{WING_CY}}' = $wingUp.cy
    '{{WARDROBE_CX}}' = $wardrobe.cx; '{{WARDROBE_CX_TOP}}' = $wardrobeTopAsset.cx
    '{{WARDROBE_CY}}' = $wardrobe.cy; '{{WARDROBE_CY_TOP}}' = $wardrobeTopAsset.cy
    '{{BLANKET_CX}}' = $blanket.cx; '{{BLANKET_CY}}' = $blanket.cy
    '{{TV_CX}}' = $tv.cx; '{{TV_CY}}' = $tv.cy
    '{{BG_CX}}' = $bg.cx; '{{BG_CY}}' = $bg.cy
}
foreach ($key in $replacements.Keys) { $json = $json.Replace($key, [string]$replacements[$key]) }

$utf8 = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText((Join-Path $temp "project.json"), $json, $utf8)
if (Test-Path $outSb3) { Remove-Item $outSb3 -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($temp, $outSb3)
Remove-Item $temp -Recurse -Force
Write-Host "Created: $outSb3"
