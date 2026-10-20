param([switch]$Yes)
# Cleanup is intentionally conservative: each remote ref must exactly match
# the GitHub PR head verified as merged into main on 2026-10-20.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$targets = @(
    @{ name='feature/pixel-musician-animations'; sha='b5e6834d324b75742b0e23db0bf7e224718782a1'; pr=1 },
    @{ name='perf/potato-mode'; sha='feba3435ca309a2b033ac613bd5008e6d031acb0'; pr=2 },
    @{ name='fix/portable-playable-build'; sha='a604075bf644757d2d8fc3dff347d20c18b7d8da'; pr=3 },
    @{ name='fix/template-archive-recovery'; sha='8a8dd348fce0ab33e2fd9149b7c5b074c21c0bba'; pr=4 },
    @{ name='art/animated-musicians-and-bosses'; sha='af2fcee23b21c121df9e2b4e6647ad9f1460e692'; pr=5 }
)
function Log([string]$message) {
    Write-Host "[Rhapsody Branch Cleanup] $message" -ForegroundColor Cyan
}
try {
    $git = Get-Command 'git.exe' -ErrorAction Stop
    $branch = (& $git.Source -C $root branch --show-current).Trim()
    if ($branch -ne 'main') {
        throw "Current branch is '$branch'. Switch to main first. No branches were deleted."
    }
    Log 'All five source pull requests have previously been merged into main.'
    $eligible = @()
    foreach ($target in $targets) {
        $line = & $git.Source -C $root ls-remote --heads origin ("refs/heads/" + $target.name)
        if ($LASTEXITCODE -ne 0) { throw "Cannot read remote branch $($target.name)." }
        if (-not $line) {
            Log "$($target.name) is already deleted."
            continue
        }
        $actual = (($line | Select-Object -First 1) -split '\s+')[0]
        if ($actual -ine $target.sha) {
            Write-Warning "Skipping $($target.name): branch changed since its merged PR #$($target.pr)."
            continue
        }
        $eligible += $target
    }
    if ($eligible.Count -eq 0) {
        Log 'No old merged remote branches remain eligible for deletion.'
        exit 0
    }
    Log ("The following {0} exact, already-merged branch references can be deleted:" -f $eligible.Count)
    foreach ($target in $eligible) {
        Write-Host ("  - {0} (merged PR #{1})" -f $target.name, $target.pr)
    }
    if (-not $Yes) {
        $answer = Read-Host 'Delete only these remote branches? Type DELETE to confirm'
        if ($answer -cne 'DELETE') {
            Log 'Cancelled. No branches were deleted.'
            exit 0
        }
    }
    foreach ($target in $eligible) {
        Log "Deleting remote $($target.name)..."
        & $git.Source -C $root push origin --delete $target.name
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Could not delete $($target.name); check GitHub authentication."
            continue
        }
        # Only remove a matching local branch, never a divergent local branch.
        & $git.Source -C $root show-ref --verify --quiet ("refs/heads/" + $target.name)
        if ($LASTEXITCODE -eq 0) {
            $localSha = (& $git.Source -C $root rev-parse ("refs/heads/" + $target.name)).Trim()
            if ($localSha -ieq $target.sha) {
                & $git.Source -C $root branch -D $target.name
            }
        }
    }
    Log 'Completed. Check the GitHub Branches page; main should be the only branch.'
}
catch {
    Write-Host ("CLEANUP ERROR: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
