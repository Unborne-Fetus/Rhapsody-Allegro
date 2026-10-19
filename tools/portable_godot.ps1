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
$release = 'https://github.com/godotengine/godot/releases/download/4.5.1-stable'
$editorName = 'Godot_v4.5.1-stable_win64_console.exe'
$archiveName = 'Godot_v4.5.1-stable_win64.exe.zip'
$editor = Join-Path $portable $editorName

function Log([string]$Message) {
    Write-Host "[Rhapsody] $Message" -ForegroundColor Cyan
}

function Fetch([string]$Url, [string]$Destination) {
    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if (Test-Path $Destination) { return }
    Log "Downloading $([System.IO.Path]::GetFileName($Destination)) (first run only)..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -TimeoutSec 900
    }
    catch {
        Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        throw "Could not download $Url : $($_.Exception.Message)"
    }
}

function CheckSha256([string]$File, [string]$Expected) {
    $actual = (Get-FileHash -Algorithm SHA256 -Path $File).Hash
    if ($actual -ne $Expected) {
        Remove-Item -LiteralPath $File -Force -ErrorAction SilentlyContinue
        throw "Integrity check failed for $File. Please retry."
    }
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
    Fetch "$release/$archiveName" $archive
    # Official Godot 4.5.1 Windows x64 archive, from Microsoft's winget manifest.
    CheckSha256 $archive 'DEFCCC78669E644861B4247626B01AE362CD9F23975EDF19C8BFD2EB1F6A1783'
    Log 'Extracting portable Godot editor...'
    Expand-Archive -LiteralPath $archive -DestinationPath $portable -Force
    if (-not (Test-Path $editor)) {
        throw "The Godot archive was extracted, but $editorName is missing."
    }
    Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
}

function EnsureTemplates {
    $templateDir = Join-Path $env:APPDATA 'Godot\export_templates\4.5.1.stable'
    $required = @('web_release.zip', 'windows_release_x86_64.exe')
    $missing = @($required | Where-Object { -not (Test-Path (Join-Path $templateDir $_)) })
    if ($missing.Count -eq 0) { return }
    Log 'Export templates are required for making standalone builds.'
    Log 'The official template archive is large; this is a one-time download.'
    if (-not (Test-Path $templateDir)) {
        New-Item -ItemType Directory -Path $templateDir -Force | Out-Null
    }
    $templateArchive = Join-Path $portable 'Godot_v4.5.1-stable_export_templates.tpz'
    Fetch "$release/Godot_v4.5.1-stable_export_templates.tpz" $templateArchive
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($templateArchive)
    $extracted = @{}
    try {
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName.Replace('\', '/')
            if ($name -notlike 'templates/*') { continue }
            $fileName = [System.IO.Path]::GetFileName($name)
            if ($fileName -notin @('web_release.zip', 'web_debug.zip',
                                  'windows_release_x86_64.exe', 'windows_debug_x86_64.exe')) {
                continue
            }
            $destination = Join-Path $templateDir $fileName
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $true)
            $extracted[$fileName] = $true
        }
    }
    finally {
        $zip.Dispose()
    }
    foreach ($name in $required) {
        if (-not (Test-Path (Join-Path $templateDir $name))) {
            throw "The template archive did not include $name. Check the downloaded Godot version."
        }
    }
    Remove-Item -LiteralPath $templateArchive -Force -ErrorAction SilentlyContinue
    Log "Installed the Windows and Web export templates only ($($extracted.Count) files)."
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
    exit 1
}
exit 0
