param(
    [ValidateSet('Normal', 'Tests')][string]$Mode = 'Tests',
    [string]$Compiler,
    [string]$Dotnet,
    [switch]$KeepProject,
    [switch]$Analyze
)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$tempRoot = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'BCAA-Performance'))
if ($tempRoot.StartsWith($repo.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'TEMP must be outside the AL project. Generated AL sources cannot be staged inside the repository.'
}
if (-not $Compiler) {
    $extension = Get-ChildItem -LiteralPath (Join-Path $env:USERPROFILE '.vscode/extensions') -Directory |
        Where-Object Name -Like 'ms-dynamics-smb.al-*' |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $extension) { throw 'Install the AL VS Code extension or specify -Compiler.' }
    $Compiler = Join-Path $extension.FullName 'bin/alc.dll'
}
if (-not $Dotnet) {
    $Dotnet = Join-Path $repo '.build/dotnet10/dotnet.exe'
    if (-not (Test-Path -LiteralPath $Dotnet)) { $Dotnet = Join-Path $tempRoot 'dotnet10/dotnet.exe' }
    if (-not (Test-Path -LiteralPath $Dotnet)) { $Dotnet = 'dotnet' }
}
# .gitignore / Explorer exclusions do not isolate AL source from F5.
# Only packages and JSON diagnostics belong in .build, never source projects.
$build = Join-Path $repo '.build'
if (Test-Path -LiteralPath $build) {
    if (Get-ChildItem -LiteralPath $build -Recurse -File -Filter '*.al' | Select-Object -First 1) {
        throw 'Stale AL sources exist under .build. Move generated project folders outside this repository before building.'
    }
}
New-Item -ItemType Directory -Path $build -Force | Out-Null
$stage = Join-Path $tempRoot ($Mode + '-' + [guid]::NewGuid().ToString('N'))
$output = Join-Path $repo ('.build/BCAA-performance-' + $Mode + '.app')
$diagnosticsName = if ($Analyze) { 'permissions-PTE-' + $Mode + '.json' } else { 'performance-' + $Mode + '-diagnostics.json' }
$diagnostics = Join-Path $build $diagnosticsName
$succeeded = $false
try {
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    $manifest = Get-Content -LiteralPath (Join-Path $repo 'app.json') -Raw | ConvertFrom-Json
    $symbols = @($manifest.preprocessorSymbols | Where-Object {
        $_ -and $_ -notin @('BCG_PERF_TESTS', 'BCG_SOURCE_COUNT_TESTS', 'BCG_AFFECTED_USER_TESTS')
    })
    if ($Mode -eq 'Tests') { $symbols += @('BCG_PERF_TESTS', 'BCG_SOURCE_COUNT_TESTS', 'BCG_AFFECTED_USER_TESTS') }
    $manifest | Add-Member -NotePropertyName preprocessorSymbols -NotePropertyValue @($symbols) -Force
    $manifest | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $stage 'app.json') -Encoding UTF8
    Get-ChildItem -LiteralPath $repo -Filter '*.al' -File | Copy-Item -Destination $stage
    Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.al' -File | Copy-Item -Destination $stage
    if ($KeepProject) {
        $vscode = Join-Path $stage '.vscode'
        New-Item -ItemType Directory -Path $vscode | Out-Null
        $launch = Get-Content -LiteralPath (Join-Path $repo '.vscode/launch.json') -Raw | ConvertFrom-Json
        $sandbox = @($launch.configurations | Where-Object { $_.type -eq 'al' -and $_.environmentType -eq 'Sandbox' })
        if ($sandbox.Count -ne 1) { throw 'Expected exactly one Sandbox AL launch configuration.' }
        $config = $sandbox[0]
        if ($Mode -eq 'Tests') {
            $config.name = 'BCAA Performance Sandbox'
            $config.startupObjectId = 50960
            $config.startupObjectType = 'Page'
        }
        @{ version = '0.2.0'; configurations = @($config) } | ConvertTo-Json -Depth 20 |
            Set-Content -LiteralPath (Join-Path $vscode 'launch.json') -Encoding UTF8
        @{ 'al.packageCachePath' = @((Join-Path $repo '.alpackages')) } | ConvertTo-Json |
            Set-Content -LiteralPath (Join-Path $vscode 'settings.json') -Encoding UTF8
    }
    # Compile to the standard name inside the external project, so its F5 build
    # publishes the same manifest/symbol configuration without editing the real app.
    $packageName = '{0}_{1}_{2}.app' -f $manifest.publisher, $manifest.name, $manifest.version
    $stagedPackage = Join-Path $stage $packageName
    $compilerArguments = @("/project:$stage", "/packagecachepath:$repo/.alpackages", "/out:$stagedPackage", "/errorlog:$diagnostics")
    if ($Analyze) {
        foreach ($analyzer in @('PerTenantExtensionCop', 'CodeCop', 'UICop')) {
            $analyzerPath = Join-Path (Split-Path -Parent $Compiler) ('Microsoft.Dynamics.Nav.' + $analyzer + '.dll')
            if (-not (Test-Path -LiteralPath $analyzerPath)) { throw "Analyzer not found: $analyzerPath" }
            $compilerArguments += "/analyzer:$analyzerPath"
        }
    }
    & $Dotnet $Compiler @compilerArguments
    $compilerExit = $LASTEXITCODE
    if (-not (Test-Path -LiteralPath $diagnostics)) { throw 'AL compiler did not produce diagnostics.' }
    $issues = (Get-Content -LiteralPath $diagnostics -Raw | ConvertFrom-Json).issues
    if ($issues | Where-Object { $_.properties.severity -eq 'Error' }) { throw "AL compile errors: $diagnostics" }
    if ($compilerExit -ne 0) { throw "AL compiler exit code $compilerExit" }
    Copy-Item -LiteralPath $stagedPackage -Destination $output
    $succeeded = $true
    Write-Output "Package: $output"
    Write-Output "Diagnostics: $diagnostics"
    if ($KeepProject) {
        Write-Output "Disposable project: $stage"
        Write-Output "Open in a SEPARATE window: code --new-window `"$stage`""
        Write-Output 'Press F5 in that window. Do not add this project to the normal workspace.'
    }
}
finally {
    if (-not $KeepProject -or -not $succeeded) {
        $resolvedStage = [IO.Path]::GetFullPath($stage)
        if (-not $resolvedStage.StartsWith($tempRoot.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Refusing cleanup outside the performance temporary directory.'
        }
        if (Test-Path -LiteralPath $resolvedStage) {
            Remove-Item -LiteralPath $resolvedStage -Recurse -Force
        }
    }
}
