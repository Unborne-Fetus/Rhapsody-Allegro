param(
    [ValidateSet('play', 'build')]
    [string]$Mode = 'play',
    [switch]$SkipTests
)

# Portable Godot 4.5.1. No admin rights, GitHub Actions, or third-party installers.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$portable = Join-Path $root 'tools\.portable-godot'
$release = 'https://github.com/godotengine/godot-builds/releases/download/4.5.1-stable'
$editorName = 'Godot_v4.5.1-stable_win64_console.exe'
$archiveName = 'Godot_v4.5.1-stable_win64.exe.zip'
$editor = Join-Path $portable $editorName

function Log([string]$Message) {
    Write-Host "[Rhapsody] $Message" -ForegroundColor Cyan
}

# Pinned to the official Godot 4.5.1-stable GitHub release assets.
$editorBytes = [long]76685794
$editorSha256 = 'DEFCCC78669E644861B4247626B01AE362CD9F23975EDF19C8BFD2EB1F6A1783'
$templateBytes = [long]1355592535
$templateSha256 = '1998AF37F1387684E2C211CDB483DAF492FC64DC6B12096BDDCDCA25B6910C86'

function FetchVerified([string]$Url, [string]$Destination,
                       [long]$ExpectedBytes, [string]$ExpectedSha256) {
    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    for ($attempt = 1; $attempt -le 4; $attempt++) {
        $existingBytes = [long]0
        if (Test-Path -LiteralPath $Destination) {
            $existingBytes = (Get-Item -LiteralPath $Destination).Length
            if ($existingBytes -eq $ExpectedBytes) {
                Log "Checking SHA256 of $([IO.Path]::GetFileName($Destination))..."
                $sha256 = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
                if ($sha256 -ieq $ExpectedSha256) {
                    Log 'Archive size and checksum verified.'
                    return
                }
                Write-Warning 'Cached file has a bad checksum. Deleting it.'
                Remove-Item -LiteralPath $Destination -Force
                $existingBytes = 0
            } elseif ($existingBytes -gt $ExpectedBytes) {
                Write-Warning 'Cached file is larger than the official release. Deleting it.'
                Remove-Item -LiteralPath $Destination -Force
                $existingBytes = 0
            }
        }
        Log ("Download attempt {0}/4: {1:N1} of {2:N1} MiB already received." -f $attempt, ($existingBytes / 1048576), ($ExpectedBytes / 1048576))
        $curl = Get-Command 'curl.exe' -ErrorAction SilentlyContinue
        if ($null -ne $curl) {
            # Resume large interrupted downloads instead of treating any existing
            # file as complete. curl.exe ships with Windows 10/11.
            $curlArgs = @('--fail', '--location', '--retry', '3',
                          '--retry-delay', '4', '--connect-timeout', '30',
                          '--progress-bar', '--show-error', '--output', $Destination)
            if ($existingBytes -gt 0) { $curlArgs += @('--continue-at', '-') }
            $curlArgs += @($Url)
            & $curl.Source @curlArgs
            $downloadExit = $LASTEXITCODE
        } else {
            if (Test-Path -LiteralPath $Destination) {
                Remove-Item -LiteralPath $Destination -Force
            }
            try {
                Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -TimeoutSec 1800
                $downloadExit = 0
            } catch {
                Write-Warning "Download was interrupted: $($_.Exception.Message)"
                $downloadExit = 1
            }
        }
        $receivedBytes = [long]0
        if (Test-Path -LiteralPath $Destination) {
            $receivedBytes = (Get-Item -LiteralPath $Destination).Length
        }
        if ($downloadExit -eq 0 -and $receivedBytes -eq $ExpectedBytes) {
            $sha256 = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
            if ($sha256 -ieq $ExpectedSha256) {
                Log 'Archive size and SHA256 verified.'
                return
            }
            Write-Warning 'Downloaded file failed checksum verification. Retrying cleanly.'
            Remove-Item -LiteralPath $Destination -Force
        } else {
            Write-Warning ("Incomplete download: {0:N1} / {1:N1} MiB, exit code {2}." -f ($receivedBytes / 1048576), ($ExpectedBytes / 1048576), $downloadExit)
            if ($receivedBytes -gt $ExpectedBytes -or $receivedBytes -lt 1024 -or $downloadExit -eq 33) {
                # Tiny files may be error pages; exit 33 means HTTP resume unsupported.
                Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
            }
        }
    }
    throw "Could not download and verify the official Godot archive after four attempts. The partial file can be resumed on your next build: $Destination"
}

function EnsureEditor {
    if ($env:GODOT) {
        if (-not (Test-Path $env:GODOT)) { throw "GODOT points to a missing file: $env:GODOT" }
        $script:editor = (Resolve-Path $env:GODOT).Path
        Log "Using selected Godot editor: $script:editor"
        return
    }
    if (Test-Path $editor) { return }
    if (-not (Test-Path $portable)) {
        New-Item -ItemType Directory -Path $portable -Force | Out-Null
    }
    $archive = Join-Path $portable $archiveName
    FetchVerified "$release/$archiveName" $archive $editorBytes $editorSha256
    Log 'Extracting portable Godot editor...'
    Expand-Archive -LiteralPath $archive -DestinationPath $portable -Force
    if (-not (Test-Path $editor)) {
        throw "The Godot archive was extracted, but $editorName is missing."
    }
    Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
}

function EnsureTemplates {
    $templateDir = Join-Path $env:APPDATA 'Godot\export_templates\4.5.1.stable'
    # Unthreaded Web exports require web_nothreads_release.zip.
    $required = @('version.txt', 'web_release.zip', 'web_nothreads_release.zip',
                  'windows_release_x86_64.exe')
    $selected = @('version.txt', 'web_release.zip', 'web_debug.zip',
                  'web_nothreads_release.zip', 'web_nothreads_debug.zip',
                  'windows_release_x86_64.exe', 'windows_debug_x86_64.exe',
                  'windows_release_x86_64_console.exe',
                  'windows_debug_x86_64_console.exe')
    $missing = @($required | Where-Object {
        $candidate = Join-Path $templateDir $_
        -not (Test-Path -LiteralPath $candidate) -or
            (Get-Item -LiteralPath $candidate).Length -eq 0
    })
    if ($missing.Count -eq 0) {
        Log 'Windows and Web release export templates are already installed.'
        return
    }
    Log 'Installing official Godot 4.5.1 export templates (1.26 GiB one-time download).'
    Log 'Incomplete downloads are resumed; invalid files are discarded automatically.'
    if (-not (Test-Path -LiteralPath $templateDir)) {
        New-Item -ItemType Directory -Path $templateDir -Force | Out-Null
    }
    $templateArchive = Join-Path $portable 'Godot_v4.5.1-stable_export_templates.tpz'
    FetchVerified "$release/Godot_v4.5.1-stable_export_templates.tpz" $templateArchive $templateBytes $templateSha256
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $stage = Join-Path $portable 'templates-stage'
    if (Test-Path -LiteralPath $stage) {
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    $zip = $null
    try {
        Log 'Extracting Windows and Web templates into a temporary staging folder...'
        $zip = [System.IO.Compression.ZipFile]::OpenRead($templateArchive)
        foreach ($entry in $zip.Entries) {
            $entryName = $entry.FullName.Replace('\', '/')
            if (-not $entryName.StartsWith('templates/')) { continue }
            $fileName = [IO.Path]::GetFileName($entryName)
            if ($fileName -notin $selected) { continue }
            $destination = Join-Path $stage $fileName
            # Two-argument overload is compatible with Windows PowerShell 5.1.
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination)
        }
        foreach ($name in $required) {
            $candidate = Join-Path $stage $name
            if (-not (Test-Path -LiteralPath $candidate) -or
                    (Get-Item -LiteralPath $candidate).Length -eq 0) {
                throw "Archive lacks required $name. Confirm Godot version is 4.5.1."
            }
        }
        foreach ($name in $selected) {
            $source = Join-Path $stage $name
            if (Test-Path -LiteralPath $source) {
                Move-Item -LiteralPath $source -Destination (Join-Path $templateDir $name) -Force
            }
        }
    }
    catch {
        throw "Export-template extraction failed: $($_.Exception.Message)"
    }
    finally {
        if ($null -ne $zip) { $zip.Dispose() }
        if (Test-Path -LiteralPath $stage) {
            Remove-Item -LiteralPath $stage -Recurse -Force
        }
    }
    Remove-Item -LiteralPath $templateArchive -Force -ErrorAction SilentlyContinue
    Log 'Godot Web (including non-threaded) and Windows templates are installed.'
}

function RunGodot([string]$Description, [string[]]$Arguments) {
    Log $Description
    & $script:editor @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Godot failed ($Description), exit code $LASTEXITCODE. Fix the displayed error and retry."
    }
}

function ExportBuilds {
    $build = Join-Path $root 'build'
    $web = Join-Path $build 'web'
    $windows = Join-Path $build 'windows'
    New-Item -ItemType Directory -Path $web,$windows -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $build '.gdignore') -Value '' -NoNewline

    RunGodot 'Importing project assets' @('--headless', '--path', $root, '--editor', '--import', '--quit')
    RunGodot 'Exporting playable Windows EXE' @('--headless', '--path', $root, '--export-release', 'Windows', (Join-Path $windows 'Rhapsody-Allegro.exe'))
    RunGodot 'Exporting playable Web game' @('--headless', '--path', $root, '--export-release', 'Web', (Join-Path $web 'index.html'))

    $windowsExe = Join-Path $windows 'Rhapsody-Allegro.exe'
    $webHtml = Join-Path $web 'index.html'
    if (-not (Test-Path $windowsExe) -or -not (Test-Path $webHtml)) {
        throw 'Export returned without producing the Windows EXE or Web index.html.'
    }

    # Optional split-WASM static-host package. Standard Web export works without Python.
    $python = Get-Command 'py.exe' -ErrorAction SilentlyContinue
    if ($null -ne $python) {
        Log 'Preparing CDN-friendly website package...'
        & $python.Source -3 (Join-Path $root 'tools\package_web.py')
        if ($LASTEXITCODE -ne 0) { throw 'Web packager failed.' }
    } else {
        $python = Get-Command 'python.exe' -ErrorAction SilentlyContinue
        if ($null -ne $python) {
            & $python.Source (Join-Path $root 'tools\package_web.py')
            if ($LASTEXITCODE -ne 0) { throw 'Web packager failed.' }
        } else {
            Write-Warning 'Python not found: raw Godot Web export is still usable locally.'
        }
    }
    $dist = Join-Path $root 'dist'
    $webToZip = $web
    if (Test-Path (Join-Path $dist 'index.html')) { $webToZip = $dist }

    $winZip = Join-Path $build 'Rhapsody-Allegro-Windows.zip'
    $webZip = Join-Path $build 'Rhapsody-Allegro-Web.zip'
    Log 'Packing portable release ZIPs...'
    Compress-Archive -Path (Join-Path $windows '*') -DestinationPath $winZip -Force
    Compress-Archive -Path (Join-Path $webToZip '*') -DestinationPath $webZip -Force
    Log 'Playable exports created:'
    Log "  $windowsExe"
    Log "  $winZip"
    Log "  $webZip"

    if ($SkipTests) {
        Write-Warning 'Validation was skipped. This is a build, not a verified release.'
        return
    }
    $tests = @('combat_test', 'advanced_test', 'input_test',
               'weapon_test', 'song_boss_test', 'phone_test')
    foreach ($name in $tests) {
        RunGodot "Testing $name" @('--headless', '--path', $root, '--script', "res://tests/$name.gd")
    }
    Log 'All six Godot regression suites passed.'
}

try {
    Set-Location $root
    EnsureEditor
    if ($Mode -eq 'play') {
        # A fresh Git checkout does not include Godot's ignored texture import
        # cache. Import before the first play so SVG and PNG textures can load.
        RunGodot 'Importing/refreshing playable project assets' @('--headless', '--path', $root, '--editor', '--import', '--quit')
        Log 'Starting the real Godot project (no export templates needed)...'
        & $script:editor --path $root
        if ($LASTEXITCODE -ne 0) { throw "The game exited with code $LASTEXITCODE." }
    } else {
        EnsureTemplates
        ExportBuilds
    }
}
catch {
    Write-Host ''
    Write-Host ('BUILD ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    $logDirectory = Join-Path $root 'build'
    if (-not (Test-Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }
    $errorPath = Join-Path $logDirectory 'last-build-error.txt'
    ($_ | Out-String) | Set-Content -LiteralPath $errorPath
    Write-Host ('Error details saved to: ' + $errorPath) -ForegroundColor Yellow
    exit 1
}
exit 0
