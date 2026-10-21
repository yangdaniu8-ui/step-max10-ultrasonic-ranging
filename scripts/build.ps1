param(
    [string]$QuartusBin = '',
    [ValidateSet('step_ultrasonic','board_display_selftest')]
    [string]$Project = 'step_ultrasonic'
)
$ErrorActionPreference = 'Stop'
if ($QuartusBin) {
    $quartusShell = Join-Path $QuartusBin 'quartus_sh.exe'
} elseif ($env:QUARTUS_ROOTDIR) {
    $candidates = @(
        (Join-Path $env:QUARTUS_ROOTDIR 'bin64\quartus_sh.exe'),
        (Join-Path $env:QUARTUS_ROOTDIR 'bin\quartus_sh.exe')
    )
    $quartusShell = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
} else {
    $command = Get-Command quartus_sh -ErrorAction SilentlyContinue
    if ($command) { $quartusShell = $command.Source }
}
if (!$quartusShell -or !(Test-Path -LiteralPath $quartusShell)) {
    throw 'Quartus not found. Add quartus_sh to PATH, set QUARTUS_ROOTDIR, or pass -QuartusBin.'
}
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location (Join-Path $projectRoot 'quartus')
try {
    & $quartusShell --flow compile $Project
    if ($LASTEXITCODE -ne 0) { throw "Quartus compilation failed for $Project." }
} finally { Pop-Location }
