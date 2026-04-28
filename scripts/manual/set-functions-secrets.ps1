param(
    [string]$ProjectId = "apapane-94356",
    [string]$EnvFile = ".env",
    [string]$PlayServiceAccountJsonPath = "",
    [string]$AppleSharedSecret = ""
)

$ErrorActionPreference = "Stop"

function Get-EnvValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not (Test-Path $EnvFile)) {
        return ""
    }

    $line = Get-Content $EnvFile | Where-Object { $_ -match "^$Name=" } | Select-Object -First 1
    if (-not $line) {
        return ""
    }

    return ($line -split "=", 2)[1].Trim()
}

function Set-SecretFromValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        Write-Host "Skipping $Name because no value was provided." -ForegroundColor Yellow
        return
    }

    $tempFile = Join-Path $env:TEMP ("$Name-" + [guid]::NewGuid().ToString() + ".txt")
    Set-Content -Path $tempFile -Value $Value -NoNewline
    try {
        npx firebase-tools functions:secrets:set $Name --project $ProjectId --data-file $tempFile --force
    }
    finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

function Set-SecretFromFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-Host "Skipping $Name because no file path was provided." -ForegroundColor Yellow
        return
    }

    if (-not (Test-Path $Path)) {
        throw "Secret file not found for ${Name}: $Path"
    }

    npx firebase-tools functions:secrets:set $Name --project $ProjectId --data-file $Path --force
}

$geminiApiKey = Get-EnvValue -Name "GEMINI_API_KEY"
Set-SecretFromValue -Name "GEMINI_API_KEY" -Value $geminiApiKey
Set-SecretFromFile -Name "PLAY_SERVICE_ACCOUNT_JSON" -Path $PlayServiceAccountJsonPath
Set-SecretFromValue -Name "APPLE_SHARED_SECRET" -Value $AppleSharedSecret
