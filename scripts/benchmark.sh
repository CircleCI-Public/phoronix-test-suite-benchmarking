#!/usr/bin/env bash
#
# Run the pinned benchmark set non-interactively (PTS batch mode) and save the
# results under the given name.
#
#   Usage: benchmark.sh <result-name>
#
# Requires install.sh to have run first (PTS installed + batch mode configured).
# Env: FORCE_TIMES_TO_RUN (default: 3), PTS_TESTS / PTS_PRESET_OPTIONS overrides.
#
set -euo pipefail

RESULT="${1:?usage: benchmark.sh <result-name>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/benchmark-set.sh
. "${SCRIPT_DIR}/benchmark-set.sh"

# Non-interactive result naming; PRESET_OPTIONS picks each test's option;
# FORCE_TIMES_TO_RUN pins the run count (and disables PTS's dynamic run count,
# which otherwise keeps adding trials).
export TEST_RESULTS_NAME="${RESULT}"
export TEST_RESULTS_IDENTIFIER="${RESULT}"
export TEST_RESULTS_DESCRIPTION="${RESULT}"
export PRESET_OPTIONS="${PTS_PRESET_OPTIONS}"
export FORCE_TIMES_TO_RUN="${FORCE_TIMES_TO_RUN:-3}"

# shellcheck disable=SC2086  # PTS_TESTS must word-split into separate arguments
phoronix-test-suite batch-benchmark ${PTS_TESTS}
