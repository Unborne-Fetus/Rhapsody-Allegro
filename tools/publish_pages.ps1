param(
    [switch]$StageOnly
)
# Publishes a pre-built Godot Web export through the existing main branch.
# No additional git branch and no GitHub Actions runner are required.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$docs = Join-Path $root 'docs'
$dest = Join-Path $docs 'play'
$stage = Join-Path $docs '.pages-staging'
$dist = Join-Path $root 'dist'
$rawWeb = Join-Path $root 'build\web'

function Log([string]$msg) {
    Write-Host "[Rhapsody Pages] $msg" -ForegroundColor Cyan
}

try {
    $source = $null
    if (Test-Path -LiteralPath (Join-Path $dist 'index.html')) {
        $source = $dist
    } elseif (Test-Path -LiteralPath (Join-Path $rawWeb 'index.html')) {
        $source = $rawWeb
    } else {
        throw 'No playable Web export found. Run build.bat before publishing.'
    }

    # Do not push a blank landing page or a partial Godot export.
    $needed = @('index.html','index.js')
    foreach ($name in $needed) {
        $item = Join-Path $source $name
        if (-not (Test-Path -LiteralPath $item) -or
            (Get-Item -LiteralPath $item).Length -eq 0) {
            throw "Missing or empty Godot Web runtime file: $item"
        }
    }
    $packs = @(Get-ChildItem -LiteralPath $source -Filter '*.pck' -File)
    if ($packs.Count -eq 0) { throw 'No Godot .pck game content found; export incomplete.' }
    $wasm = Join-Path $source 'index.wasm'
    $engineParts = @(Get-ChildItem -LiteralPath $source -Filter 'engine-*.bin' -File)
    if (-not (Test-Path -LiteralPath $wasm) -and $engineParts.Count -eq 0) {
        throw 'No Godot WASM engine or split engine chunks found; export incomplete.'
    }

    if (-not (Test-Path -LiteralPath (Join-Path $docs '.nojekyll'))) {
        [System.IO.File]::WriteAllText((Join-Path $docs '.nojekyll'), '')
    }
    if (-not (Test-Path -LiteralPath (Join-Path $docs 'index.html'))) {
        throw 'docs/index.html is missing: pull the newest main branch first.'
    }
    if (Test-Path -LiteralPath $stage) {
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
    New-Item -ItemType Directory -Path $stage -Force | Out-Null

    Log 'Preparing a fresh copy of the built Godot browser game...'
    Copy-Item -Path (Join-Path $source '*') -Destination $stage -Recurse -Force
    # .gdignore and _headers are build-system metadata, not needed by Pages.
    foreach ($unneeded in @('.gdignore', '_headers')) {
        $remove = Join-Path $stage $unneeded
        if (Test-Path -LiteralPath $remove) {
            Remove-Item -LiteralPath $remove -Force
        }
    }

    # Stage first. Replace the previous published version only after copying
    # and verifying the new one, to avoid leaving docs/play half-populated.
    foreach ($name in $needed) {
        if (-not (Test-Path -LiteralPath (Join-Path $stage $name))) {
            throw "Staged version is missing $name."
        }
    }
    if (Test-Path -LiteralPath $dest) {
        Remove-Item -LiteralPath $dest -Recurse -Force
    }
    Move-Item -LiteralPath $stage -Destination $dest
    Log 'Web game staged to docs/play/ on main.'

    if ($StageOnly) {
        Log 'Stage-only requested. Commit/push docs/play, docs/index.html and docs/.nojekyll to main to publish.'
        exit 0
    }

    $git = Get-Command 'git.exe' -ErrorAction SilentlyContinue
    if ($null -eq $git) {
        Write-Warning 'Git is not installed. The Web game is staged locally; commit/push docs/ using GitHub Desktop instead.'
        exit 0
    }
    $branch = (& $git.Source -C $root branch --show-current).Trim()
    if ($branch -ne 'main') {
        throw "Refusing to publish from branch '$branch'. Switch to main and pull the latest changes first."
    }

    Log 'Committing only the staged GitHub Pages files (not other local edits)...'
    & $git.Source -C $root add -A -- docs/play docs/index.html docs/.nojekyll
    if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
    & $git.Source -C $root diff --cached --quiet -- docs/play docs/index.html docs/.nojekyll
    if ($LASTEXITCODE -eq 0) {
        Log 'This Web export is already committed; nothing new to push.'
        exit 0
    }
    if ($LASTEXITCODE -ne 1) { throw 'git diff check failed.' }
    & $git.Source -C $root commit --only -m 'Publish playable Godot Web export to main/docs' -- docs/play docs/index.html docs/.nojekyll
    if ($LASTEXITCODE -ne 0) {
        throw 'Git commit failed. Check your Git name and email configuration.'
    }

    Log 'Pushing the updated playable site to origin/main...'
    & $git.Source -C $root push origin main
    if ($LASTEXITCODE -ne 0) {
        throw 'Git push failed. Check login and pull/rebase origin/main if your local branch is behind.'
    }
    Log 'Playable Godot Web assets pushed to main/docs/play.'
    Log 'Set GitHub Settings -> Pages -> Deploy from a branch -> main /docs (once).'
    Log 'Expected site URL: https://unborne-fetus.github.io/Rhapsody-Allegro/'
}
catch {
    if (Test-Path -LiteralPath $stage) {
        Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host ("PAGES PUBLISH ERROR: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
