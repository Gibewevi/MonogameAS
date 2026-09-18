param(
    [string]$OutputDirectory = 'artifacts/cloud-compatibility',
    [string]$BinaryDirectory = '',
    [string]$BaselineRevision = 'HEAD'
)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$capture = [IO.Path]::GetFullPath((Join-Path $repo $OutputDirectory))
$taskTemp = Join-Path ([IO.Path]::GetTempPath()) ('MonogameAS-CloudCompatibility-' + [guid]::NewGuid().ToString('N'))
$baselineRoot = Join-Path $taskTemp 'baseline'
New-Item -ItemType Directory -Path $baselineRoot -Force | Out-Null
$binaryRoot = if ($BinaryDirectory) { [IO.Path]::GetFullPath($BinaryDirectory) } else { Join-Path $taskTemp 'game' }
if (-not $BinaryDirectory) {
    dotnet build (Join-Path $repo 'MonogameAS.csproj') --no-restore -p:UseAppHost=false -o $binaryRoot
    if ($LASTEXITCODE -ne 0) { throw 'Current game build failed.' }
}
# Build the actual historical source, rather than copying its formulas into a test.
$revision = git -C $repo rev-parse "$BaselineRevision^{commit}"
if ($LASTEXITCODE -ne 0) { throw 'Could not resolve cloud baseline revision.' }
$archivePath = Join-Path $taskTemp 'baseline-src.tar'
git -C $repo archive --format=tar "--output=$archivePath" $revision src
if ($LASTEXITCODE -ne 0) { throw 'Could not extract cloud baseline source.' }
tar -xf $archivePath -C $baselineRoot
if ($LASTEXITCODE -ne 0) { throw 'Could not unpack cloud baseline source.' }
$escapedBinary = [System.Security.SecurityElement]::Escape($binaryRoot)
$baselineProject = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework><Nullable>enable</Nullable>
    <AssemblyName>MonogameAS.CloudBaseline</AssemblyName><EnableDefaultCompileItems>false</EnableDefaultCompileItems>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="src/**/*.cs" Exclude="src/Program.cs" />
    <Reference Include="MonoGame.Framework"><HintPath>$escapedBinary/MonoGame.Framework.dll</HintPath></Reference>
  </ItemGroup>
</Project>
"@
$baselineProjectPath = Join-Path $baselineRoot 'CloudBaseline.csproj'
Set-Content -LiteralPath $baselineProjectPath -Value $baselineProject -Encoding UTF8
dotnet build $baselineProjectPath --nologo --verbosity quiet
if ($LASTEXITCODE -ne 0) { throw 'Historical cloud source build failed.' }
$source = [System.Security.SecurityElement]::Escape((Join-Path $PSScriptRoot 'CloudCompatibility.cs.txt'))
$project = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType><TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable><EnableDefaultCompileItems>false</EnableDefaultCompileItems>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="$source" />
    <Reference Include="MonogameAS"><HintPath>$escapedBinary/MonogameAS.dll</HintPath></Reference>
    <Reference Include="MonoGame.Framework"><HintPath>$escapedBinary/MonoGame.Framework.dll</HintPath></Reference>
    <Content Include="$escapedBinary/runtimes/win-x64/native/SDL2.dll" Link="SDL2.dll" CopyToOutputDirectory="PreserveNewest" />
    <Content Include="$escapedBinary/runtimes/win-x64/native/openal.dll" Link="openal.dll" CopyToOutputDirectory="PreserveNewest" />
  </ItemGroup>
</Project>
"@
$projectPath = Join-Path $taskTemp 'CloudCompatibility.csproj'
Set-Content -LiteralPath $projectPath -Value $project -Encoding UTF8
dotnet build $projectPath --nologo --verbosity quiet
if ($LASTEXITCODE -ne 0) { throw 'Cloud compatibility harness build failed.' }
$baselineDll = Join-Path $baselineRoot 'bin/Debug/net9.0/MonogameAS.CloudBaseline.dll'
dotnet (Join-Path $taskTemp 'bin/Debug/net9.0/CloudCompatibility.dll') $baselineDll $repo $baselineRoot $capture $revision
if ($LASTEXITCODE -ne 0) { throw 'Cloud compatibility validation failed.' }
Write-Output "Cloud compatibility report: $capture"
Write-Output "Historical baseline revision: $revision"
Write-Output "Game binary directory: $binaryRoot"
Write-Output "Temporary validation project: $taskTemp"
