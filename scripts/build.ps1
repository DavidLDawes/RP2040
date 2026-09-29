<#
.SYNOPSIS
    Build grblHAL for one board type and role, and check the image.

.DESCRIPTION
    Configures build-<board>-<role>/ with an explicit -DPICO_BOARD every time (an
    automatic CMake re-run would otherwise fall back to "pico", see
    Controller/PICO2-PLAN.md 1.3), injects roles/<role>.cmake, builds, then checks the
    image and copies it to build-<board>-<role>/grblHAL-<board>-<role>.uf2.

    The checks print, and fail on a mismatch:
      - the chip the image was built for (PICO_PLATFORM),
      - the number of axes (from the size of core's axis_letter[N_AXIS]),
      - the settings (NVS) address, which must be the last 32K of the board's flash.

    Give either -Board and -Role, or -Device with an id from the bench registry
    (Controller/bench/boards.json, or $env:MHS_BOARDS), which supplies both.

.EXAMPLE
    scripts\build.ps1 -Board pico2 -Role cnc
.EXAMPLE
    scripts\build.ps1 -Device cnc-2
#>
[CmdletBinding(DefaultParameterSetName = 'Explicit')]
param(
    [Parameter(ParameterSetName = 'Explicit', Mandatory)]
    [ValidateSet('pico', 'pico_w', 'pico2', 'pico2_w')]
    [string]$Board,

    [Parameter(ParameterSetName = 'Explicit', Mandatory)]
    [string]$Role,

    [Parameter(ParameterSetName = 'Registry', Mandatory)]
    [string]$Device,

    # Toolchain directory laid out like ~/play/toolchain (pico-sdk, arm-gnu-*, cmake-*, mingw-*).
    [string]$Toolchain = $(if ($env:PICO_TOOLCHAIN_DIR) { $env:PICO_TOOLCHAIN_DIR } else { Join-Path $HOME 'play/toolchain' }),

    # Delete the build directory first.
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot

# --------------------------------------------------------------- board and role

if ($PSCmdlet.ParameterSetName -eq 'Registry') {
    $registry = if ($env:MHS_BOARDS) { $env:MHS_BOARDS } else { Join-Path $repo '../bench/boards.json' }
    if (-not (Test-Path $registry)) { throw "bench registry not found: $registry (set MHS_BOARDS)" }
    $entry = (Get-Content $registry -Raw | ConvertFrom-Json).devices | Where-Object { $_.id -eq $Device }
    if (-not $entry) { throw "no device '$Device' in $registry" }
    if ($entry.kind -ne 'grblhal') { throw "device '$Device' is a $($entry.kind), not a grblHAL board" }
    $Board = $entry.board
    $Role = $entry.role
    Write-Host "device $Device -> board $Board, role $Role ($registry)"
}

$roleFile = Join-Path $repo "roles/$Role.cmake"
if (-not (Test-Path $roleFile)) {
    $known = (Get-ChildItem (Join-Path $repo 'roles') -Filter *.cmake | ForEach-Object BaseName) -join ', '
    throw "no role '$Role' (roles/$Role.cmake); known roles: $known"
}

$platform = if ($Board -like 'pico2*') { 'rp2350-arm-s' } else { 'rp2040' }
$flashKB = if ($Board -like 'pico2*') { 4096 } else { 2048 }

# ------------------------------------------------------------------- toolchain

foreach ($part in 'pico-sdk') {
    if (-not (Test-Path (Join-Path $Toolchain $part))) { throw "toolchain not found at $Toolchain (use -Toolchain or PICO_TOOLCHAIN_DIR)" }
}
$env:PICO_SDK_PATH = (Resolve-Path (Join-Path $Toolchain 'pico-sdk')).Path -replace '\\', '/'
$bins = @('mingw-*/bin', 'cmake-*/bin', 'arm-gnu-*/bin') | ForEach-Object {
    Get-ChildItem (Join-Path $Toolchain $_) -Directory -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
}
# the toolchain's mingw must come first (see the toolchain's env.sh)
$env:PATH = (@($bins) + $Toolchain + $env:PATH) -join [IO.Path]::PathSeparator

# ----------------------------------------------------------------------- build

$build = Join-Path $repo "build-$Board-$Role"
if ($Clean -and (Test-Path $build)) { Remove-Item -Recurse -Force $build }

$roleCMake = $roleFile -replace '\\', '/'
& cmake -G Ninja -S $repo -B $build "-DPICO_BOARD=$Board" -DPICO_NO_COPRO_DIS=1 "-DCMAKE_PROJECT_grblHAL_INCLUDE=$roleCMake"
if ($LASTEXITCODE) { throw "configure failed" }
& cmake --build $build
if ($LASTEXITCODE) { throw "build failed" }

# ---------------------------------------------------------------------- checks

$elf = Join-Path $build 'grblHAL.elf'
$problems = @()

$cachedPlatform = (Select-String -Path (Join-Path $build 'CMakeCache.txt') -Pattern '^PICO_PLATFORM:STRING=(.*)$').Matches[0].Groups[1].Value
if ($cachedPlatform -ne $platform) { $problems += "built for $cachedPlatform, expected $platform" }

$axisLetter = & arm-none-eabi-nm -S $elf | Where-Object { $_ -match '\saxis_letter$' }
$axes = if ($axisLetter) { [Convert]::ToInt32(($axisLetter -split '\s+')[1], 16) / 4 } else { '?' }

$nvs = & arm-none-eabi-objdump -d --disassemble=memcpy_to_flash $elf |
    Select-String -Pattern '0x10[0-9a-f]{6}' -AllMatches | ForEach-Object { $_.Matches.Value } | Sort-Object -Unique
$nvsExpected = '0x{0:x}' -f (0x10000000 + ($flashKB - 32) * 1024)
if (@($nvs).Count -ne 1 -or $nvs -ne $nvsExpected) { $problems += "settings at '$nvs', expected $nvsExpected" }

$uf2 = Join-Path $build "grblHAL-$Board-$Role.uf2"
Copy-Item (Join-Path $build 'grblHAL.uf2') $uf2 -Force

Write-Host ""
Write-Host "board    $Board ($cachedPlatform, ${flashKB}K flash)"
Write-Host "role     $Role"
Write-Host "axes     $axes"
Write-Host "settings $nvs"
Write-Host "image    $uf2"
if ($problems) {
    $problems | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    exit 1
}
