#
# Install PHP, the Phoronix Test Suite (from git), configure it for
# non-interactive batch runs, and install the pinned benchmark test profiles.
#
# Runs on Windows Server 2025 with Chocolatey pre-installed (CircleCI Windows
# machine executor images). Env: PTS_REF (default: master),
# PTS_INSTALL_TESTS (default: true -- set false to skip test profile install).
#
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\benchmark-set.ps1"

$PTS_REF = if ($env:PTS_REF) { $env:PTS_REF } else { "master" }
$PTS_INSTALL_TESTS = if ($env:PTS_INSTALL_TESTS) { $env:PTS_INSTALL_TESTS } else { "true" }

Write-Host "== Installing PHP =="
choco install php -y --no-progress
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
refreshenv

# Enable required PHP extensions for PTS.
$phpDir = (Get-Command php -ErrorAction SilentlyContinue).Source | Split-Path -Parent
if (-not $phpDir) {
    $phpDir = "C:\tools\php"
    $env:PATH = "$phpDir;$env:PATH"
}
$phpIni = Join-Path $phpDir "php.ini"
if (-not (Test-Path $phpIni)) {
    Copy-Item (Join-Path $phpDir "php.ini-production") $phpIni
}
@("extension_dir = `"ext`"", "extension=curl", "extension=gd", "extension=zip", "extension=openssl", "extension=mbstring") | ForEach-Object {
    Add-Content $phpIni $_
}
php --version

Write-Host "== Installing Phoronix Test Suite ($PTS_REF) from git =="
if (Test-Path C:\PTS) { Remove-Item -Recurse -Force C:\PTS }
git clone --depth 1 --branch $PTS_REF `
    https://github.com/phoronix-test-suite/phoronix-test-suite.git C:\PTS

Write-Host "== Configuring PTS for non-interactive batch runs =="
php C:\PTS\pts-core\phoronix-test-suite.php enterprise-setup
php C:\PTS\pts-core\phoronix-test-suite.php user-config-set `
    PhoronixTestSuite/Options/BatchMode/Configured=TRUE `
    PhoronixTestSuite/Options/BatchMode/SaveResults=TRUE `
    PhoronixTestSuite/Options/BatchMode/PromptForTestIdentifier=FALSE `
    PhoronixTestSuite/Options/BatchMode/PromptForTestDescription=FALSE `
    PhoronixTestSuite/Options/BatchMode/PromptSaveName=FALSE `
    PhoronixTestSuite/Options/BatchMode/OpenBrowser=FALSE `
    PhoronixTestSuite/Options/BatchMode/UploadResults=FALSE `
    PhoronixTestSuite/Options/BatchMode/RunAllTestCombinations=FALSE

if ($PTS_INSTALL_TESTS -eq "true") {
    Write-Host "== Installing benchmark tests =="
    $tests = $PTS_TESTS -split '\s+'
    php C:\PTS\pts-core\phoronix-test-suite.php install @tests
} else {
    Write-Host "== Skipping benchmark test install (PTS_INSTALL_TESTS=$PTS_INSTALL_TESTS) =="
}

Write-Host "== install.ps1 complete =="
