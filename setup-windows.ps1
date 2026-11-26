#Requires -Version 5.1
<#
.SYNOPSIS
    Prepare a Windows development environment for Tycho.

.DESCRIPTION
    Windows counterpart of setup-linux.sh. Verifies what `moon build
    --target native` compiles with and what the examples load at runtime:

      * MSVC x64 compiler + Windows SDK (the native backend locates Visual
        Studio itself through vswhere, so no developer prompt is required)
      * Vulkan loader (vulkan-1.dll, 1.3+) and the MoonBit CLI
      * glslangValidator for laplaceliu/tycho_shader
      * vendored Vulkan headers and vk.xml used by codegen

    A Slang release passed with -SlangPath is linked into third_party\slang as
    a junction (no copy, no admin rights), mirroring the symlink that
    setup-linux.sh creates.

.PARAMETER SlangPath
    Root of an extracted Slang release: the directory holding bin\slangc.exe.

.EXAMPLE
    .\setup-windows.ps1

.EXAMPLE
    .\setup-windows.ps1 C:\SDK\slang-2026.22-windows-x86_64
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$SlangPath
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$script:missing = $false

function Stop-WithError {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "ERROR: $Message"
    exit 1
}

function Write-Ok {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host ("  ok       {0}" -f $Message)
}

function Write-Missing {
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$Hint
    )
    Write-Host ("  MISSING  {0}  ->  {1}" -f $Message, $Hint)
    $script:missing = $true
}

function Write-Warn {
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$Hint
    )
    Write-Host ("  warn     {0}  ->  {1}" -f $Message, $Hint)
}

function Find-Application {
    param([Parameter(Mandatory)][string]$Name)
    $command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($command) { return $command.Source }
    return $null
}

function Find-Msvc {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path -LiteralPath $vswhere) {
        $vsPath = & $vswhere -latest -products * `
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
            -property installationPath 2>$null
        if ($vsPath) {
            $msvcRoot = Join-Path $vsPath 'VC\Tools\MSVC'
            $cl = Get-ChildItem -LiteralPath $msvcRoot -Directory -ErrorAction SilentlyContinue |
                Sort-Object -Property Name -Descending |
                ForEach-Object { Join-Path $_.FullName 'bin\Hostx64\x64\cl.exe' } |
                Where-Object { Test-Path -LiteralPath $_ } |
                Select-Object -First 1
            if ($cl) {
                $version = 'unknown'
                if ($cl -match 'MSVC\\(?<version>[^\\]+)\\bin\\') { $version = $Matches['version'] }
                return [pscustomobject]@{
                    Path    = $cl
                    Version = $version
                    VcVars  = Join-Path $vsPath 'VC\Auxiliary\Build\vcvars64.bat'
                    Root    = $vsPath
                }
            }
        }
    }

    # Fall back to a shell that already ran vcvars64.bat.
    $onPath = Find-Application 'cl.exe'
    if ($onPath) {
        return [pscustomobject]@{
            Path    = $onPath
            Version = 'unknown'
            VcVars  = $null
            Root    = Split-Path -Parent $onPath
        }
    }
    return $null
}

function Test-MsvcProbe {
    param([Parameter(Mandatory)][pscustomobject]$Msvc)

    # Compile a real C11 program: this proves the compiler plus the Windows SDK
    # headers/import libraries are all usable, not just that cl.exe exists.
    $id = [Guid]::NewGuid().ToString('N')
    $src = Join-Path $env:TEMP "tycho_cc_probe_$id.c"
    $obj = Join-Path $env:TEMP "tycho_cc_probe_$id.obj"
    $exe = Join-Path $env:TEMP "tycho_cc_probe_$id.exe"
    $bat = Join-Path $env:TEMP "tycho_cc_probe_$id.bat"

    Set-Content -LiteralPath $src -Encoding Ascii `
        -Value 'int main(void){int x=0;for(int i=0;i<1;i++){x+=i;}return x;}'

    $lines = @('@echo off')
    if ($Msvc.VcVars) { $lines += "call `"$($Msvc.VcVars)`" >nul 2>&1" }
    $lines += "`"$($Msvc.Path)`" /nologo /std:c11 /Fe:`"$exe`" /Fo:`"$obj`" `"$src`" /link /subsystem:console >nul 2>&1"
    Set-Content -LiteralPath $bat -Encoding Ascii -Value $lines

    try {
        & cmd.exe /c $bat | Out-Null
        return ((Test-Path -LiteralPath $exe) -and ($LASTEXITCODE -eq 0))
    } finally {
        Remove-Item -LiteralPath $src, $obj, $exe, $bat -Force -ErrorAction SilentlyContinue
    }
}

function Find-WindowsSdk {
    $roots = New-Object System.Collections.Generic.List[string]
    if ($env:WindowsSdkDir) { $roots.Add($env:WindowsSdkDir.TrimEnd('\')) }
    $roots.Add((Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10'))

    foreach ($root in $roots) {
        $include = Join-Path $root 'Include'
        if (-not (Test-Path -LiteralPath $include)) { continue }
        foreach ($dir in (Get-ChildItem -LiteralPath $include -Directory -ErrorAction SilentlyContinue |
                    Sort-Object -Property Name -Descending)) {
            $um = Join-Path $dir.FullName 'um\windows.h'
            $lib = Join-Path $root ("Lib\{0}\um\x64\user32.lib" -f $dir.Name)
            if ((Test-Path -LiteralPath $um) -and (Test-Path -LiteralPath $lib)) {
                return $dir.Name
            }
        }
    }
    return $null
}

function Find-VulkanLoader {
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($env:TYCHO_VULKAN_LIB) { $candidates.Add($env:TYCHO_VULKAN_LIB) }
    $candidates.Add((Join-Path $env:SystemRoot 'System32\vulkan-1.dll'))

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return (Get-Item -LiteralPath $candidate -Force).FullName
        }
    }
    return $null
}

function Get-VulkanLoaderVersion {
    param([Parameter(Mandatory)][string]$Loader)

    $code = @"
using System;
using System.Runtime.InteropServices;

public static class TychoVulkanLoaderProbe
{
    [DllImport(@"$Loader")]
    public static extern int vkEnumerateInstanceVersion(out uint version);
}
"@
    if (-not ('TychoVulkanLoaderProbe' -as [type])) {
        Add-Type -TypeDefinition $code
    }
    [uint32]$version = 0
    if ([TychoVulkanLoaderProbe]::vkEnumerateInstanceVersion([ref]$version) -ne 0) {
        return $null
    }
    return $version
}

function Format-VulkanVersion {
    param([Parameter(Mandatory)][uint32]$Version)
    return ('{0}.{1}.{2}' -f ($Version -shr 22), (($Version -shr 12) -band 0x3FF), ($Version -band 0xFFF))
}

function Find-Glslang {
    if ($env:TYCHO_GLSLANG -and (Test-Path -LiteralPath $env:TYCHO_GLSLANG)) {
        return (Get-Item -LiteralPath $env:TYCHO_GLSLANG -Force).FullName
    }
    $onPath = Find-Application 'glslangValidator'
    if ($onPath) { return $onPath }

    $roots = New-Object System.Collections.Generic.List[string]
    if ($env:VULKAN_SDK) { $roots.Add($env:VULKAN_SDK) }
    $sdkRoot = Join-Path $env:SystemDrive 'VulkanSDK'
    if (Test-Path -LiteralPath $sdkRoot) {
        foreach ($dir in (Get-ChildItem -LiteralPath $sdkRoot -Directory -ErrorAction SilentlyContinue |
                    Sort-Object -Property Name -Descending)) {
            $roots.Add($dir.FullName)
        }
    }
    foreach ($root in $roots) {
        foreach ($relative in @('Bin\glslangValidator.exe', 'bin\glslangValidator.exe')) {
            $candidate = Join-Path $root $relative
            if (Test-Path -LiteralPath $candidate) { return $candidate }
        }
    }
    return $null
}

function Find-Python {
    $commands = Get-Command python, python3 -CommandType Application -ErrorAction SilentlyContinue
    foreach ($command in $commands) {
        try {
            $output = (& $command.Source --version 2>&1 | Select-Object -First 1)
            if (($LASTEXITCODE -eq 0) -and ($output -match 'Python\s+(?<version>\d+\.\d+\.\d+)')) {
                return [pscustomobject]@{ Path = $command.Source; Version = $Matches['version'] }
            }
        } catch {
            # Microsoft Store python stub: no output, non-zero exit.
        }
    }
    return $null
}

Write-Host '== picking a C compiler =='
$msvc = Find-Msvc
$probeOk = $false
if ($msvc) {
    $probeOk = Test-MsvcProbe -Msvc $msvc
}
if (-not $msvc) {
    Write-Host '  no cl.exe found: install Visual Studio Build Tools with the "Desktop development with C++" workload'
} elseif ($probeOk) {
    Write-Host ("  cl.exe -> {0} (MSVC {1}), C11 probe ok" -f $msvc.Root, $msvc.Version)
} else {
    Write-Host ("  cl.exe -> {0} (MSVC {1}), C11 probe FAILED" -f $msvc.Path, $msvc.Version)
}

Write-Host '== checking native dependencies =='
$moon = Find-Application 'moon'
if ($moon) {
    $moonVersion = (& $moon version 2>&1 | Select-Object -First 1)
    if (-not $moonVersion) { $moonVersion = $moon }
    Write-Ok ("MoonBit CLI ({0})" -f $moonVersion)
} else {
    Write-Missing 'MoonBit CLI (moon)' `
        'install it: irm https://cli.moonbitlang.com/install/powershell.ps1 | iex, then reopen the shell'
}

if (($msvc) -and ($probeOk)) {
    Write-Ok ("MSVC x64 compiler {0}" -f $msvc.Version)
} elseif ($msvc) {
    Write-Missing 'MSVC x64 compiler (C11 probe failed)' `
        'repair the "Desktop development with C++" workload in the Visual Studio Installer'
} else {
    Write-Missing 'MSVC x64 compiler (cl.exe)' `
        'install Visual Studio Build Tools with the "Desktop development with C++" workload'
}

$sdk = Find-WindowsSdk
if ($sdk) {
    Write-Ok ("Windows SDK {0}" -f $sdk)
} else {
    Write-Missing 'Windows SDK (um\windows.h + user32.lib)' `
        'add the "Windows 11 SDK" component in the Visual Studio Installer'
}

$loader = Find-VulkanLoader
if (-not $loader) {
    Write-Missing 'Vulkan loader (vulkan-1.dll, 1.3+)' `
        'install the GPU driver or the Vulkan SDK, or set TYCHO_VULKAN_LIB to a vulkan-1.dll'
} else {
    $loaderOk = $true
    $versionText = 'version unknown'
    try {
        $loaderVersion = Get-VulkanLoaderVersion -Loader $loader
        if ($null -ne $loaderVersion) {
            $versionText = Format-VulkanVersion -Version $loaderVersion
            $major = $loaderVersion -shr 22
            $minor = ($loaderVersion -shr 12) -band 0x3FF
            if (($major -lt 1) -or (($major -eq 1) -and ($minor -lt 3))) { $loaderOk = $false }
        }
    } catch {
        # Keep the presence check: the RHI only needs the entry points it loads itself.
    }
    if ($loaderOk) {
        Write-Ok ("Vulkan loader {0} ({1})" -f $versionText, $loader)
    } else {
        Write-Missing ("Vulkan loader {0} ({1})" -f $versionText, $loader) `
            'the RHI requires loader 1.3+: update the GPU driver or install a newer Vulkan SDK'
    }
}

$glslang = Find-Glslang
if ($glslang) {
    Write-Ok ("glslangValidator ({0})" -f $glslang)
} else {
    Write-Missing 'glslangValidator (tycho_shader)' `
        'install the Vulkan SDK (winget install KhronosGroup.VulkanSDK) and add Bin to PATH, or set TYCHO_GLSLANG'
}

if (Test-Path -LiteralPath 'vulkan\include\vulkan\vulkan_core.h') {
    Write-Ok 'vendored Vulkan headers'
} else {
    Write-Missing 'vendored Vulkan headers' 'committed in vulkan/include/vulkan'
}

if (Test-Path -LiteralPath 'codegen\registry\vk.xml') {
    Write-Ok 'vendored vk.xml'
} else {
    Write-Missing 'vendored vk.xml' 'committed in codegen/registry'
}

$python = Find-Python
if ($python) {
    Write-Ok ("Python {0} ({1})" -f $python.Version, $python.Path)
} else {
    Write-Warn 'Python 3 (tools/run-ci-suite.py)' 'install it: winget install Python.Python.3.12'
}

if ($SlangPath) {
    if (-not (Test-Path -LiteralPath $SlangPath -PathType Container)) {
        Stop-WithError "$SlangPath is not a directory (expected a Slang release root)."
    }
    $slangAbs = (Get-Item -LiteralPath $SlangPath -Force).FullName
    if (-not (Test-Path -LiteralPath (Join-Path $slangAbs 'bin\slangc.exe'))) {
        Write-Host ("  WARNING: {0}\bin\slangc.exe not found; is this a Slang release root?" -f $slangAbs)
    }

    New-Item -ItemType Directory -Force -Path (Join-Path $PWD 'third_party') | Out-Null
    $link = Join-Path (Join-Path $PWD 'third_party') 'slang'
    $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if (-not ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            Stop-WithError "$link exists and is a real directory; delete it manually and re-run."
        }
        # Directory.Delete drops the reparse point itself, never the target tree.
        [System.IO.Directory]::Delete($link)
    }

    $linked = $false
    try {
        New-Item -ItemType Junction -Path $link -Target $slangAbs | Out-Null
        $linked = $true
    } catch {
        if (Test-Path -LiteralPath $link) { [System.IO.Directory]::Delete($link) }
        try {
            New-Item -ItemType SymbolicLink -Path $link -Target $slangAbs | Out-Null
            $linked = $true
        } catch {
            Stop-WithError "cannot link $link -> $slangAbs (enable Windows Developer Mode for symlinks, or keep the release on a local drive)"
        }
    }
    if ($linked) {
        Write-Host ("  third_party/slang -> {0}" -f $slangAbs)
    }
}

if ($script:missing) {
    Write-Host 'Some dependencies are missing; install them and re-run.'
    exit 1
}
Write-Host 'Ready. Build with: moon build --target native'
