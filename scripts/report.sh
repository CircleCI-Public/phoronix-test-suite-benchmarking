#!/usr/bin/env bash
#
# Merge per-executor result files into a single self-contained HTML report and
# place it in ./reports.
#
#   Usage: report.sh [result-name ...]   (defaults to: gen1 gen2 gen3)
#
# result-file-to-html renders graphs as inline SVG (no GD rasterizer), avoiding
# the result-file-to-pdf path's PHP 8.3 deprecation flood / stall.
#
set -euo pipefail

results=("$@")
if [ "${#results[@]}" -eq 0 ]; then
  results=(gen1 gen2 gen3)
fi

if [ "${#results[@]}" -gt 1 ]; then
  # Merge the per-executor results into one comparison result file.
  target=$(phoronix-test-suite merge-results "${results[@]}" | grep -oE 'merge-[0-9]+' | head -1)
else
  # A single result has nothing to merge -- report it directly.
  target="${results[0]}"
fi

phoronix-test-suite result-file-to-html "${target}"
mkdir -p reports
mv ~/*.html reports/
