param([string]$ModelSimBin = '')
$ErrorActionPreference = 'Stop'
if ($ModelSimBin) {
    $simulator = Join-Path $ModelSimBin 'vsim.exe'
} else {
    $command = Get-Command vsim -ErrorAction SilentlyContinue
    if ($command) { $simulator = $command.Source }
}
if (!$simulator -or !(Test-Path -LiteralPath $simulator)) {
    throw 'ModelSim not found. Add vsim to PATH or pass -ModelSimBin.'
}
$projectRoot = Split-Path -Parent $PSScriptRoot
$buildDirectory = Join-Path $projectRoot 'build'
New-Item -ItemType Directory -Path $buildDirectory -Force | Out-Null
$cases = @(
    @{ Name='ranging'; Do='run.do'; Marker='ALL TESTS PASSED' },
    @{ Name='tone'; Do='run_buzzer_tone.do'; Marker='TONE TEST PASSED' },
    @{ Name='display'; Do='run_display_selftest.do'; Marker='SELFTEST PASSED' }
)
Push-Location (Join-Path $projectRoot 'sim')
try {
    foreach ($case in $cases) {
        $logPath = Join-Path $buildDirectory ($case.Name + '.log')
        & $simulator -c -l $logPath -do $case.Do
        if ($LASTEXITCODE -ne 0) { throw "Simulation failed: $($case.Name)." }
        $logText = Get-Content -LiteralPath $logPath -Raw
        if (!$logText.Contains($case.Marker)) { throw "Missing success marker: $($case.Name)." }
    }
} finally { Pop-Location }
