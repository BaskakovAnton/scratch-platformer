$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$outSb3 = Join-Path $root "platformer.sb3"
$template = Join-Path $root "project.template.json"
$temp = Join-Path $env:TEMP ("scratch-build-" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Force -Path $temp | Out-Null

function Get-ImageSize([string]$path) {
    $img = [System.Drawing.Image]::FromFile($path)
    try { return @{ W = $img.Width; H = $img.Height } }
    finally { $img.Dispose() }
}

function Import-Asset([string]$sourcePath) {
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
    }
}

$field = Import-Asset (Join-Path $root "backgrounds\stage_field.png")
$start = Import-Asset (Join-Path $root "backgrounds\stage_start.png")
$hero = Import-Asset (Join-Path $root "sprites\hero.png")
$house = Import-Asset (Join-Path $root "sprites\house.png")
$platform = Import-Asset (Join-Path $root "sprites\platform_ground.png")
$enemy = Import-Asset (Join-Path $root "sprites\rhinoceros.png")

$json = Get-Content $template -Raw -Encoding UTF8
$json = $json.Replace('{{FIELD_MD5}}', $field.md5)
$json = $json.Replace('{{FIELD_MD5EXT}}', $field.md5ext)
$json = $json.Replace('{{START_MD5}}', $start.md5)
$json = $json.Replace('{{START_MD5EXT}}', $start.md5ext)
$json = $json.Replace('{{HERO_MD5}}', $hero.md5)
$json = $json.Replace('{{HERO_MD5EXT}}', $hero.md5ext)
$json = $json.Replace('{{HERO_CX}}', $hero.cx)
$json = $json.Replace('{{HERO_CY}}', $hero.cy)
$json = $json.Replace('{{HOUSE_MD5}}', $house.md5)
$json = $json.Replace('{{HOUSE_MD5EXT}}', $house.md5ext)
$json = $json.Replace('{{HOUSE_CX}}', $house.cx)
$json = $json.Replace('{{HOUSE_CY}}', $house.cy)
$json = $json.Replace('{{PLATFORM_MD5}}', $platform.md5)
$json = $json.Replace('{{PLATFORM_MD5EXT}}', $platform.md5ext)
$json = $json.Replace('{{PLATFORM_CX}}', $platform.cx)
$json = $json.Replace('{{PLATFORM_CY}}', $platform.cy)
$json = $json.Replace('{{ENEMY_MD5}}', $enemy.md5)
$json = $json.Replace('{{ENEMY_MD5EXT}}', $enemy.md5ext)
$json = $json.Replace('{{ENEMY_CX}}', $enemy.cx)
$json = $json.Replace('{{ENEMY_CY}}', $enemy.cy)

$utf8 = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText((Join-Path $temp "project.json"), $json, $utf8)

if (Test-Path $outSb3) { Remove-Item $outSb3 -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($temp, $outSb3)
Remove-Item $temp -Recurse -Force
Write-Host "Created: $outSb3"
