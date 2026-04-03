param(
  [string]$OutputDir = "store_assets/google-play/screenshots"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

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

function Save-StoreScreenshot {
  param(
    [string]$InputPath,
    [string]$OutputPath,
    [int]$CanvasWidth,
    [int]$CanvasHeight,
    [string]$Headline,
    [string]$Subline
  )

  $source = [System.Drawing.Image]::FromFile($InputPath)
  $bitmap = [System.Drawing.Bitmap]::new($CanvasWidth, $CanvasHeight)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

  $backgroundRect = [System.Drawing.Rectangle]::new(0, 0, $CanvasWidth, $CanvasHeight)
  $gradient = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    $backgroundRect,
    [System.Drawing.Color]::FromArgb(255, 255, 247, 232),
    [System.Drawing.Color]::FromArgb(255, 255, 236, 204),
    25.0
  )
  $graphics.FillRectangle($gradient, $backgroundRect)

  $shapeBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(110, 255, 224, 173)
  )
  $graphics.FillEllipse($shapeBrush, [int]($CanvasWidth * 0.05), [int]($CanvasHeight * 0.08), [int]($CanvasWidth * 0.28), [int]($CanvasWidth * 0.28))
  $graphics.FillEllipse($shapeBrush, [int]($CanvasWidth * 0.68), [int]($CanvasHeight * 0.68), [int]($CanvasWidth * 0.18), [int]($CanvasWidth * 0.18))

  $headlineFont = New-StoreFont -Size ([math]::Round($CanvasWidth * 0.052)) -Style ([System.Drawing.FontStyle]::Bold)
  $sublineFont = New-StoreFont -Size ([math]::Round($CanvasWidth * 0.026)) -Style ([System.Drawing.FontStyle]::Regular)
  $headlineBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 91, 52, 28)
  )
  $sublineBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 117, 88, 68)
  )

  $textLeft = [int]($CanvasWidth * 0.08)
  $textTop = [int]($CanvasHeight * 0.08)
  $textWidth = [int]($CanvasWidth * 0.84)
  $stringFormat = [System.Drawing.StringFormat]::new()
  $stringFormat.Alignment = [System.Drawing.StringAlignment]::Near
  $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Near
  $graphics.DrawString(
    $Headline,
    $headlineFont,
    $headlineBrush,
    [System.Drawing.RectangleF]::new($textLeft, $textTop, $textWidth, [int]($CanvasHeight * 0.09)),
    $stringFormat
  )
  $graphics.DrawString(
    $Subline,
    $sublineFont,
    $sublineBrush,
    [System.Drawing.RectangleF]::new($textLeft, [int]($CanvasHeight * 0.145), $textWidth, [int]($CanvasHeight * 0.08)),
    $stringFormat
  )

  $frameWidth = [int]($CanvasWidth * 0.72)
  $frameHeight = [int]($CanvasHeight * 0.64)
  $scale = [Math]::Min($frameWidth / $source.Width, $frameHeight / $source.Height)
  $imageWidth = [int][Math]::Round($source.Width * $scale)
  $imageHeight = [int][Math]::Round($source.Height * $scale)
  $frameX = [int](($CanvasWidth - $imageWidth) / 2)
  $frameY = [int]($CanvasHeight * 0.26 + (($frameHeight - $imageHeight) / 2))

  $shadowBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(42, 90, 52, 28)
  )
  $shadowPath = New-RoundedRectanglePath -Rectangle ([System.Drawing.RectangleF]::new($frameX + 10, $frameY + 14, $imageWidth, $imageHeight)) -Radius 32
  $graphics.FillPath($shadowBrush, $shadowPath)

  $frameBrush = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
  )
  $framePath = New-RoundedRectanglePath -Rectangle ([System.Drawing.RectangleF]::new($frameX, $frameY, $imageWidth, $imageHeight)) -Radius 30
  $graphics.FillPath($frameBrush, $framePath)

  $graphics.SetClip($framePath)
  $graphics.DrawImage($source, $frameX, $frameY, $imageWidth, $imageHeight)
  $graphics.ResetClip()

  $outlinePen = [System.Drawing.Pen]::new(
    [System.Drawing.Color]::FromArgb(70, 224, 170, 116),
    2
  )
  $graphics.DrawPath($outlinePen, $framePath)

  $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq "image/jpeg" } |
    Select-Object -First 1
  $encoder = [System.Drawing.Imaging.Encoder]::Quality
  $encoderParameters = [System.Drawing.Imaging.EncoderParameters]::new(1)
  $encoderParameters.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new($encoder, 92L)
  $bitmap.Save($OutputPath, $codec, $encoderParameters)

  $encoderParameters.Dispose()
  $outlinePen.Dispose()
  $framePath.Dispose()
  $frameBrush.Dispose()
  $shadowPath.Dispose()
  $shadowBrush.Dispose()
  $stringFormat.Dispose()
  $headlineFont.Dispose()
  $sublineFont.Dispose()
  $headlineBrush.Dispose()
  $sublineBrush.Dispose()
  $shapeBrush.Dispose()
  $gradient.Dispose()
  $graphics.Dispose()
  $bitmap.Dispose()
  $source.Dispose()
}

$root = Resolve-Path "."
$resolvedOutputDir = Join-Path $root $OutputDir
$null = New-Item -ItemType Directory -Force -Path $resolvedOutputDir

$shots = @(
  @{
    Path = (Resolve-Path "emulator_after_example_loaded.png")
    Headline = "おはなしを つくろう"
    Subline = "やさしい会話から AI が物語をひろげます"
    Slug = "story-builder"
  },
  @{
    Path = (Resolve-Path "emulator_after_create.png")
    Headline = "えらんで つくる"
    Subline = "イラストつきで 楽しい物語体験"
    Slug = "story-create"
  }
)

$targets = @(
  @{ Prefix = "phone"; Width = 1080; Height = 1920 },
  @{ Prefix = "tablet-7in"; Width = 1200; Height = 1920 },
  @{ Prefix = "tablet-10in"; Width = 1600; Height = 2560 }
)

$index = 1
foreach ($shot in $shots) {
  foreach ($target in $targets) {
    $fileName = "{0}-{1:D2}-{2}.jpg" -f $target.Prefix, $index, $shot.Slug
    $outputPath = Join-Path $resolvedOutputDir $fileName
    Save-StoreScreenshot `
      -InputPath $shot.Path `
      -OutputPath $outputPath `
      -CanvasWidth $target.Width `
      -CanvasHeight $target.Height `
      -Headline $shot.Headline `
      -Subline $shot.Subline
    Write-Output "Created: $outputPath"
  }
  $index += 1
}
