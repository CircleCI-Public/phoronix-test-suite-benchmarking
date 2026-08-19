#
# Shared definition of the Windows benchmark set, dot-sourced by install.ps1
# (which installs these profiles) and benchmark.ps1 (which runs them).
#
# Versions are pinned so every executor installs identical profiles (same
# rationale as the Linux benchmark-set.sh).
#
# Both variables can be overridden from environment variables.

# CI-representative Windows benchmarks:
#   compress-7zip   -- multi-threaded CPU (artifact archiving)
#   go-benchmark    -- Go compilation (shared with Linux set)
#   git             -- Git operations (every CI run starts with git)
#   compress-zstd   -- compression used by many CI caching layers
#   renaissance     -- Java workload suite (JVM-based CI tasks)
#
# renaissance has no install_windows.sh but lists Windows in SupportedPlatforms;
# PTS runs install.sh under auto-Cygwin (it just wraps a JAR). OpenJDK is
# pre-installed on the Windows Server 2025 images.
$PTS_TESTS = if ($env:PTS_TESTS) { $env:PTS_TESTS } else {
    "pts/compress-7zip-1.11.0 pts/go-benchmark-1.1.4 pts/git-1.1.0 pts/compress-zstd-1.5.0 pts/renaissance-1.0.0"
}

# Per-test option selection for batch mode. go-benchmark picks the build
# sub-test; the rest use defaults or have no configurable options.
$PTS_PRESET_OPTIONS = if ($env:PTS_PRESET_OPTIONS) { $env:PTS_PRESET_OPTIONS } else {
    "go-benchmark.run-test=build"
}
