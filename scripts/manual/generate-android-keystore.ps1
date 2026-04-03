param(
    [string]$StorePassword,
    [string]$KeyPassword,
    [string]$KeyAlias = "upload",
    [string]$DistinguishedName = "CN=Apapane, OU=Internal, O=Apapane, L=Tokyo, ST=Tokyo, C=JP"
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repoRoot

if ([string]::IsNullOrWhiteSpace($StorePassword) -or [string]::IsNullOrWhiteSpace($KeyPassword)) {
    throw "StorePassword and KeyPassword are required."
}

keytool -genkeypair `
    -v `
    -storetype JKS `
    -keystore android\app\upload-keystore.jks `
    -storepass $StorePassword `
    -keypass $KeyPassword `
    -alias $KeyAlias `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -dname $DistinguishedName

@"
storePassword=$StorePassword
keyPassword=$KeyPassword
keyAlias=$KeyAlias
storeFile=app/upload-keystore.jks
"@ | Set-Content android\key.properties

Write-Host "Created android\app\upload-keystore.jks and android\key.properties"
