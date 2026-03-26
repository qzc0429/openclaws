param(
    [Parameter(Mandatory = $true)]
    [string]$RepoUrl,
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [string]$Branch = "main",
    [string]$GithubToken = ""
)

$ErrorActionPreference = "Stop"

function Parse-OwnerRepoFromUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    $normalized = $Url.Trim()
    $match = [regex]::Match($normalized, "github\.com[:/](?<owner>[^/]+)/(?<repo>[^/.]+)(\.git)?/?$", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $match.Success) {
        throw "Cannot parse owner/repo from RepoUrl: $Url"
    }

    return "$($match.Groups['owner'].Value)/$($match.Groups['repo'].Value)"
}

function Ensure-GitRepository {
    if (-not (Test-Path ".git")) {
        git init | Out-Host
    }
}

function Ensure-OriginRemote {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    $hasOrigin = $false
    try {
        git remote get-url origin *> $null
        $hasOrigin = $true
    }
    catch {
        $hasOrigin = $false
    }

    if ($hasOrigin) {
        git remote set-url origin $Url | Out-Host
    }
    else {
        git remote add origin $Url | Out-Host
    }
}

function Commit-ChangesIfNeeded {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    git add -A | Out-Host
    $status = git status --porcelain
    if ($status) {
        git commit -m $Message | Out-Host
    }
    else {
        Write-Host "No local changes to commit." -ForegroundColor DarkGray
    }
}

function Invoke-WorkflowDispatch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OwnerRepo,
        [Parameter(Mandatory = $true)]
        [string]$WorkflowFile,
        [Parameter(Mandatory = $true)]
        [string]$Ref,
        [hashtable]$Inputs = @{},
        [Parameter(Mandatory = $true)]
        [string]$Token
    )

    $url = "https://api.github.com/repos/$OwnerRepo/actions/workflows/$WorkflowFile/dispatches"
    $headers = @{
        Authorization = "Bearer $Token"
        Accept        = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    $body = @{
        ref    = $Ref
        inputs = $Inputs
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body -ContentType "application/json" | Out-Null
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptRoot "..")).Path
Set-Location $repoRoot

$ownerRepo = Parse-OwnerRepoFromUrl -Url $RepoUrl

Ensure-GitRepository
Ensure-OriginRemote -Url $RepoUrl
Commit-ChangesIfNeeded -Message "chore: release installers v$Version"

git branch -M $Branch | Out-Host
git push -u origin $Branch | Out-Host

Write-Host ""
Write-Host "Code pushed to $ownerRepo ($Branch)." -ForegroundColor Green
Write-Host "Release page: https://github.com/$ownerRepo/releases" -ForegroundColor Cyan
Write-Host "Unified download URL (after Pages deploy): https://$($ownerRepo.Split('/')[0]).github.io/$($ownerRepo.Split('/')[1])/download/" -ForegroundColor Cyan

if ([string]::IsNullOrWhiteSpace($GithubToken)) {
    Write-Host ""
    Write-Host "GithubToken not provided. Trigger workflows manually:" -ForegroundColor Yellow
    Write-Host "1) https://github.com/$ownerRepo/actions/workflows/release-installers.yml"
    Write-Host "2) https://github.com/$ownerRepo/actions/workflows/deploy-download-page.yml"
    exit 0
}

Invoke-WorkflowDispatch -OwnerRepo $ownerRepo -WorkflowFile "release-installers.yml" -Ref $Branch -Inputs @{ version = $Version } -Token $GithubToken
Invoke-WorkflowDispatch -OwnerRepo $ownerRepo -WorkflowFile "deploy-download-page.yml" -Ref $Branch -Token $GithubToken

Write-Host ""
Write-Host "Workflows dispatched successfully." -ForegroundColor Green
Write-Host "Track runs:" -ForegroundColor Cyan
Write-Host "https://github.com/$ownerRepo/actions/workflows/release-installers.yml"
Write-Host "https://github.com/$ownerRepo/actions/workflows/deploy-download-page.yml"
