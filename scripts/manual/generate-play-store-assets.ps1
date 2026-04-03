param(
  [string]$SourceIconPath = "assets/images/app_icon.png",
  [string]$SourceBirdPath = "assets/images/apapane_icon_1.png",
  [string]$OutputDir = "store_assets/google-play",
  [string[]]$ScreenshotPaths = @(
    "emulator_debug_after_flow.png",
    "emulator_after_example_loaded.png",
    "emulator_after_create.png",
    "emulator_after_home_tap.png"
  )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function New-RoundedRectanglePath {
  param(
    [System.Drawing.RectangleF]$Rectangle,
    [float]$Radius
  )

  $diameter = $Radius * 2
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $path.AddArc($Rectangle.X, $Rectangle.Y, $diameter, $diameter, 180, 90)
  $path.AddArc($Rectangle.Right - $diameter, $Rectangle.Y, $diameter, $diameter, 270, 90)
  $path.AddArc($Rectangle.Right - $diameter, $Rectangle.Bottom - $diameter, $diameter, $diameter, 0, 90)
  $path.AddArc($Rectangle.X, $Rectangle.Bottom - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  return $path
}

function New-StoreFont {
  param(
    [float]$Size,
    [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
  )

  $fontCandidates = @(
    "Yu Gothic UI Semibold",
    "Yu Gothic UI",
    "Meiryo UI",
    "Meiryo",
    "Segoe UI"
  )

  foreach ($fontName in $fontCandidates) {
    try {
      return [System.Drawing.Font]::new($fontName, $Size, $Style)
    } catch {
      continue
    }
  }

  return [System.Drawing.Font]::new(
    [System.Drawing.FontFamily]::GenericSansSerif,
    $Size,
    $Style
  )
}

function Save-PlayIcon512 {
  param(
    [string]$InputPath,
    [string]$OutputPath
  )

  $source = [System.Drawing.Image]::FromFile($InputPath)
  $bitmap = [System.Drawing.Bitmap]::new(512, 512)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.Clear([System.Drawing.Color]::Transparent)
  $graphics.DrawImage($source, 0, 0, 512, 512)
  $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $bitmap.Dispose()
  $source.Dispose()
}

function Save-PlayFeatureGraphic {
  param(
    [string]$BirdPath,
    [string]$OutputPath
  )

  $width = 1024
  $height = 500
  $bitmap = [System.Drawing.Bitmap]::new($width, $height)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

  $backgroundRect = [System.Drawing.Rectangle]::new(0, 0, $width, $height)
  $gradient = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    $backgroundRect,
    [System.Drawing.Color]::FromArgb(255, 255, 247, 231),
    [System.Drawing.Color]::FromArgb(255, 255, 233, 196),
    25.0
  )
  $graphics.FillRectangle($gradient, $backgroundRect)

  $glowBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(120, 255, 213, 143)
  )
  $graphics.FillEllipse($glowBrush, 520, 40, 430, 430)

  $softBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(90, 255, 239, 211)
  )
  $graphics.FillEllipse($softBrush, 120, 80, 240, 240)
  $graphics.FillEllipse($softBrush, 300, 320, 170, 170)

  $accentPen = [System.Drawing.Pen]::new(
    [System.Drawing.Color]::FromArgb(80, 211, 117, 43),
    2
  )
  $graphics.DrawEllipse($accentPen, 128, 88, 224, 224)
  $graphics.DrawEllipse($accentPen, 536, 56, 398, 398)

  $bird = [System.Drawing.Image]::FromFile($BirdPath)
  $graphics.DrawImage($bird, 560, 35, 410, 410)

  $shadowBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(55, 154, 79, 24)
  )
  $graphics.FillEllipse($shadowBrush, 655, 390, 210, 28)

  $labelFont = New-StoreFont -Size 14 -Style ([System.Drawing.FontStyle]::Bold)
  $titleFont = New-StoreFont -Size 44 -Style ([System.Drawing.FontStyle]::Bold)
  $subtitleFont = New-StoreFont -Size 19 -Style ([System.Drawing.FontStyle]::Regular)

  $labelBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 165, 92, 32)
  )
  $textBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 91, 52, 28)
  )
  $subtextBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 108, 81, 64)
  )

  $pillBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 255, 240, 217)
  )
  $pillRect = [System.Drawing.RectangleF]::new(82, 84, 180, 38)
  $pillPath = New-RoundedRectanglePath -Rectangle $pillRect -Radius 19
  $graphics.FillPath($pillBrush, $pillPath)
  $graphics.DrawString("AI STORY APP", $labelFont, $labelBrush, 102, 93)

  $graphics.DrawString("Apapane", $titleFont, $textBrush, 82, 145)

  $subtitleRect = [System.Drawing.RectangleF]::new(84, 218, 380, 150)
  $stringFormat = [System.Drawing.StringFormat]::new()
  $stringFormat.Alignment = [System.Drawing.StringAlignment]::Near
  $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Near
  $graphics.DrawString(
    "Gentle AI stories for families",
    $subtitleFont,
    $subtextBrush,
    $subtitleRect,
    $stringFormat
  )

  $sparkBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 255, 188, 76)
  )
  $graphics.FillEllipse($sparkBrush, 480, 120, 10, 10)
  $graphics.FillEllipse($sparkBrush, 452, 156, 16, 16)
  $graphics.FillEllipse($sparkBrush, 430, 108, 7, 7)

  $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

  $stringFormat.Dispose()
  $pillPath.Dispose()
  $sparkBrush.Dispose()
  $subtextBrush.Dispose()
  $textBrush.Dispose()
  $labelBrush.Dispose()
  $pillBrush.Dispose()
  $subtitleFont.Dispose()
  $titleFont.Dispose()
  $labelFont.Dispose()
  $shadowBrush.Dispose()
  $bird.Dispose()
  $accentPen.Dispose()
  $softBrush.Dispose()
  $glowBrush.Dispose()
  $gradient.Dispose()
  $graphics.Dispose()
  $bitmap.Dispose()
}

function Get-FitRect {
  param(
    [int]$SourceWidth,
    [int]$SourceHeight,
    [int]$TargetWidth,
    [int]$TargetHeight
  )

  $scale = [Math]::Min($TargetWidth / $SourceWidth, $TargetHeight / $SourceHeight)
  $width = [int][Math]::Round($SourceWidth * $scale)
  $height = [int][Math]::Round($SourceHeight * $scale)
  $x = [int][Math]::Round(($TargetWidth - $width) / 2)
  $y = [int][Math]::Round(($TargetHeight - $height) / 2)
  return [System.Drawing.Rectangle]::new($x, $y, $width, $height)
}

function Get-CoverRect {
  param(
    [int]$SourceWidth,
    [int]$SourceHeight,
    [int]$TargetWidth,
    [int]$TargetHeight
  )

  $scale = [Math]::Max($TargetWidth / $SourceWidth, $TargetHeight / $SourceHeight)
  $width = [int][Math]::Round($SourceWidth * $scale)
  $height = [int][Math]::Round($SourceHeight * $scale)
  $x = [int][Math]::Round(($TargetWidth - $width) / 2)
  $y = [int][Math]::Round(($TargetHeight - $height) / 2)
  return [System.Drawing.Rectangle]::new($x, $y, $width, $height)
}

function Save-PlayScreenshot {
  param(
    [string]$InputPath,
    [string]$OutputPath,
    [int]$Width = 1080,
    [int]$Height = 1920
  )

  $source = [System.Drawing.Image]::FromFile($InputPath)
  $bitmap = [System.Drawing.Bitmap]::new($Width, $Height)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

  $coverRect = Get-CoverRect `
    -SourceWidth $source.Width `
    -SourceHeight $source.Height `
    -TargetWidth $Width `
    -TargetHeight $Height
  $graphics.DrawImage($source, $coverRect)

  $overlayBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(160, 255, 248, 236)
  )
  $graphics.FillRectangle($overlayBrush, 0, 0, $Width, $Height)

  $shadowBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(55, 78, 54, 42)
  )
  $shadowRect = [System.Drawing.RectangleF]::new(114, 76, 854, 1836)
  $shadowPath = New-RoundedRectanglePath -Rectangle $shadowRect -Radius 42
  $graphics.FillPath($shadowBrush, $shadowPath)

  $fitRect = Get-FitRect `
    -SourceWidth $source.Width `
    -SourceHeight $source.Height `
    -TargetWidth ($Width - 120) `
    -TargetHeight ($Height - 120)
  $frameRect = [System.Drawing.RectangleF]::new(
    $fitRect.X,
    $fitRect.Y,
    $fitRect.Width,
    $fitRect.Height
  )
  $framePath = New-RoundedRectanglePath -Rectangle $frameRect -Radius 36
  $frameBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
  )
  $graphics.FillPath($frameBrush, $framePath)
  $graphics.DrawImage($source, $fitRect)

  $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

  $frameBrush.Dispose()
  $framePath.Dispose()
  $shadowPath.Dispose()
  $shadowBrush.Dispose()
  $overlayBrush.Dispose()
  $graphics.Dispose()
  $bitmap.Dispose()
  $source.Dispose()
}

$root = Resolve-Path "."
$resolvedOutputDir = Join-Path $root $OutputDir
$null = New-Item -ItemType Directory -Force -Path $resolvedOutputDir

$resolvedIconPath = Resolve-Path $SourceIconPath
$resolvedBirdPath = Resolve-Path $SourceBirdPath

$iconOutputPath = Join-Path $resolvedOutputDir "play-store-icon-512.png"
$featureOutputPath = Join-Path $resolvedOutputDir "play-feature-graphic-1024x500.png"

Save-PlayIcon512 -InputPath $resolvedIconPath -OutputPath $iconOutputPath
Save-PlayFeatureGraphic -BirdPath $resolvedBirdPath -OutputPath $featureOutputPath

$phoneDir = Join-Path $resolvedOutputDir "phone"
$tablet7Dir = Join-Path $resolvedOutputDir "tablet-7in"
$tablet10Dir = Join-Path $resolvedOutputDir "tablet-10in"

$null = New-Item -ItemType Directory -Force -Path $phoneDir
$null = New-Item -ItemType Directory -Force -Path $tablet7Dir
$null = New-Item -ItemType Directory -Force -Path $tablet10Dir

for ($index = 0; $index -lt $ScreenshotPaths.Length; $index++) {
  $sourcePath = Resolve-Path $ScreenshotPaths[$index]
  $sequence = "{0:D2}" -f ($index + 1)
  $phoneOutputPath = Join-Path $phoneDir "phone-screenshot-$sequence.png"
  $tablet7OutputPath = Join-Path $tablet7Dir "tablet-7in-screenshot-$sequence.png"
  $tablet10OutputPath = Join-Path $tablet10Dir "tablet-10in-screenshot-$sequence.png"

  Save-PlayScreenshot -InputPath $sourcePath -OutputPath $phoneOutputPath
  Copy-Item -LiteralPath $phoneOutputPath -Destination $tablet7OutputPath -Force
  Copy-Item -LiteralPath $phoneOutputPath -Destination $tablet10OutputPath -Force
}

Write-Output "Created: $iconOutputPath"
Write-Output "Created: $featureOutputPath"
Write-Output "Created screenshots in: $phoneDir"
Write-Output "Created screenshots in: $tablet7Dir"
Write-Output "Created screenshots in: $tablet10Dir"
