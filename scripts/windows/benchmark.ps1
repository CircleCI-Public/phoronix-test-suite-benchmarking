#
# Run the pinned benchmark set non-interactively (PTS batch mode) and save the
# results under the given name.
#
#   Usage: benchmark.ps1 <result-name>
#
# Requires install.ps1 to have run first (PTS installed + batch mode configured).
# Env: FORCE_TIMES_TO_RUN (default: 3), PTS_TESTS / PTS_PRESET_OPTIONS overrides.
#
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Result
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\benchmark-set.ps1"

$env:TEST_RESULTS_NAME = $Result
$env:TEST_RESULTS_IDENTIFIER = $Result
$env:TEST_RESULTS_DESCRIPTION = $Result
$env:PRESET_OPTIONS = $PTS_PRESET_OPTIONS
$env:FORCE_TIMES_TO_RUN = if ($env:FORCE_TIMES_TO_RUN) { $env:FORCE_TIMES_TO_RUN } else { "3" }

$tests = $PTS_TESTS -split '\s+'
php C:\PTS\pts-core\phoronix-test-suite.php batch-benchmark @tests
