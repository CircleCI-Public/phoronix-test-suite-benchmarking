#!/usr/bin/env bash
#
# Shared definition of the benchmark set, sourced by install.sh (which installs
# these profiles) and benchmark.sh (which runs them). Keeping it here means the
# list and the per-test options live in one place.
#
# Versions are pinned so every executor installs identical profiles. Unpinned,
# `install pts/<test>` resolves "latest" and different executors can end up on
# different versions (e.g. different Linux kernels), invalidating the comparison.
#
# Both variables can be overridden from the environment (e.g. to run a subset
# locally) -- these assignments only provide the defaults.

# build-linux-kernel is pinned to 1.17.1 (builds linux-6.15), not the newest
# 1.18.0 (linux-7.0): 1.18.0 was too new to be in every executor's
# OpenBenchmarking index, so it came up "Unknown" on some and didn't run. 1.17.1
# is present in all executors' indexes, so it installs and runs consistently.
#
# The compile set spans several languages: linux-kernel/ffmpeg/imagemagick are C,
# go-benchmark (run-test=build) is Go, and build-wasmer is Rust. build-wasmer is
# pinned to 1.1.0, a version bundled in PTS's own ob-cache/test-profiles so it
# resolves on every executor without a fresh OpenBenchmarking download (same
# rationale as the build-linux-kernel pin above).
#
# NOTE: pts/java-gradle-perf was evaluated for a Java entry but is unusable in
# 2026 -- its only config (Reactor / reactor-core-3.3.5) resolves Gradle build
# plugins from repo.spring.io, which now returns HTTP 401, so the build cannot
# fetch its dependencies. PTS has no other Java *compilation* profile (the other
# Java profiles are runtime workloads, not timed builds).
PTS_TESTS="${PTS_TESTS:-pts/fs-mark-1.0.3 pts/build-linux-kernel-1.17.1 pts/node-web-tooling-1.0.1 pts/go-benchmark-1.1.4 pts/build-ffmpeg-7.0.0 pts/build-imagemagick-1.8.0 pts/build-wasmer-1.1.0}"

# Per-test option selection for batch mode. fs-mark runs every option; the rest
# pick one; node-web-tooling / build-ffmpeg / build-imagemagick / build-wasmer
# have no options.
# Format: <test>.<option-id>=<value>, ';'-delimited.
PTS_PRESET_OPTIONS="${PTS_PRESET_OPTIONS:-fs-mark.test=Test All Options;build-linux-kernel.build=defconfig;go-benchmark.run-test=build}"
