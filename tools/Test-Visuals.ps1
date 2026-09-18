param(
    [string]$OutputDirectory = 'artifacts/visual-review',
    [switch]$Baseline,
    [switch]$SkyOnly,
    [switch]$SystemOnly,
    [switch]$PlanetRestoreOnly,
    [switch]$PlanetSystemicOnly,
    [switch]$GalaxyOnly,
    [switch]$GalaxySolarOnly,
    [switch]$GalaxyBaseline,
    [string]$BinaryDirectory = '',
    [switch]$SkipBuild
)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$capture = [IO.Path]::GetFullPath((Join-Path $repo $OutputDirectory))
$taskTemp = Join-Path ([IO.Path]::GetTempPath()) ('MonogameAS-VisualReview-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $taskTemp | Out-Null
$binaryRoot = if ($BinaryDirectory) { [IO.Path]::GetFullPath($BinaryDirectory) } elseif ($SkipBuild) { Join-Path $repo 'bin/Debug/net9.0' } else { Join-Path $taskTemp 'game' }
if (-not $SkipBuild) {
    # The harness consumes a DLL. Build into its own folder so an open game keeps
    # its executable and assembly untouched and does not block visual validation.
    dotnet build (Join-Path $repo 'MonogameAS.csproj') --no-restore -p:UseAppHost=false -o $binaryRoot
    if ($LASTEXITCODE -ne 0) { throw 'Game build failed.' }
}
$escapedBinary = [System.Security.SecurityElement]::Escape($binaryRoot)
$source = [System.Security.SecurityElement]::Escape((Join-Path $PSScriptRoot 'VisualReview.cs.txt'))
$systemicSource = [System.Security.SecurityElement]::Escape((Join-Path $PSScriptRoot 'PlanetSystemicReview.cs.txt'))
$project = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType><TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable><EnableDefaultCompileItems>false</EnableDefaultCompileItems>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="$source" />
    <Compile Include="$systemicSource" />
    <Reference Include="MonogameAS"><HintPath>$escapedBinary/MonogameAS.dll</HintPath></Reference>
    <Reference Include="MonoGame.Framework"><HintPath>$escapedBinary/MonoGame.Framework.dll</HintPath></Reference>
    <Content Include="$escapedBinary/runtimes/win-x64/native/SDL2.dll" Link="SDL2.dll" CopyToOutputDirectory="PreserveNewest" />
    <Content Include="$escapedBinary/runtimes/win-x64/native/openal.dll" Link="openal.dll" CopyToOutputDirectory="PreserveNewest" />
  </ItemGroup>
</Project>
"@
$projectPath = Join-Path $taskTemp 'VisualReview.csproj'
Set-Content -LiteralPath $projectPath -Value $project -Encoding UTF8
dotnet build $projectPath --nologo --verbosity quiet
if ($LASTEXITCODE -ne 0) { throw 'Visual validation harness build failed.' }
$mode = if ($PlanetSystemicOnly) { 'planet-systemic' } elseif ($GalaxySolarOnly) { 'galaxy-solar' } elseif ($GalaxyBaseline) { 'galaxy-baseline' } elseif ($GalaxyOnly) { 'galaxy' } elseif ($PlanetRestoreOnly) { 'planet-restore' } elseif ($SystemOnly) { 'system' } elseif ($SkyOnly) { 'sky' } elseif ($Baseline) { 'baseline' } else { 'review' }
dotnet (Join-Path $taskTemp 'bin/Debug/net9.0/VisualReview.dll') $repo $capture $mode $binaryRoot
if ($LASTEXITCODE -ne 0) { throw 'Visual validation failed.' }
Write-Output "Captures and report: $capture"
Write-Output "Temporary validation project: $taskTemp"
Write-Output "Game binary directory: $binaryRoot"
