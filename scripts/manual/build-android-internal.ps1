param(
    [int]$BuildNumber = 1
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repoRoot

$requiredFiles = @(
    ".env",
    "android\key.properties",
    "android\app\upload-keystore.jks"
)

$missingFiles = $requiredFiles | Where-Object { -not (Test-Path $_) }
if ($missingFiles.Count -gt 0) {
    throw "Missing required files: $($missingFiles -join ', ')"
}

flutter pub get
flutter build appbundle --release --build-number $BuildNumber --dart-define-from-file=.env

Write-Host "Created build\app\outputs\bundle\release\app-release.aab"
