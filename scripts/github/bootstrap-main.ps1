param(
    [string]$Repository = "COROLE/apapane_v2",
    [string]$SourceBranch = "master",
    [string]$TargetBranch = "main",
    [string]$RequiredCheck = "validate"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI (gh) is required."
}

gh auth status | Out-Null
git fetch origin $SourceBranch
git push origin "refs/heads/$SourceBranch:refs/heads/$TargetBranch"
gh repo edit $Repository --default-branch $TargetBranch

$protection = @{
    required_status_checks = @{
        strict = $true
        contexts = @($RequiredCheck)
    }
    enforce_admins = $true
    required_pull_request_reviews = $null
    restrictions = $null
    required_linear_history = $true
    allow_force_pushes = $false
    allow_deletions = $false
    block_creations = $false
    required_conversation_resolution = $true
    lock_branch = $false
    allow_fork_syncing = $true
} | ConvertTo-Json -Depth 5

$tempFile = New-TemporaryFile
Set-Content -Path $tempFile -Value $protection -NoNewline

gh api `
    --method PUT `
    -H "Accept: application/vnd.github+json" `
    "/repos/$Repository/branches/$TargetBranch/protection" `
    --input $tempFile

Remove-Item $tempFile -Force
