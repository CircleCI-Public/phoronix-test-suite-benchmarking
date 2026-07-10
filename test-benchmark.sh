#!/usr/bin/env bash
#
# Build the local image (./Dockerfile runs scripts/install.sh) and run
# scripts/benchmark.sh inside it -- the same scripts CI uses, so this exercises
# the real thing. Set FAST=1 to run only the quick tests (skip the slow
# source-compile tests: kernel, ffmpeg, imagemagick).
#
# Overridable via environment:
#   BASE_IMAGE         Base image (default: cimg/base:current-24.04, as in CI)
#   PTS_REF            phoronix-test-suite git ref (default: master)
#   PLATFORM           Target platform (default: linux/amd64, to match CI)
#   RESULT_NAME        Result name (default: local-test)
#   IMAGE_TAG          Built image tag (default: pts-benchmark)
#   FORCE_TIMES_TO_RUN Run count per test (default: 3)
#   FAST               Set to 1 to skip the slow source-compile tests
#
set -euo pipefail

BASE_IMAGE="${BASE_IMAGE:-cimg/base:current-24.04}"
PTS_REF="${PTS_REF:-master}"
PLATFORM="${PLATFORM:-linux/amd64}"
RESULT_NAME="${RESULT_NAME:-local-test}"
IMAGE_TAG="${IMAGE_TAG:-pts-benchmark}"
FORCE_TIMES_TO_RUN="${FORCE_TIMES_TO_RUN:-3}"
FAST="${FAST:-0}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== Building image (runs scripts/install.sh; cached after first run) =="
docker build --platform "${PLATFORM}" \
  --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
  --build-arg "PTS_REF=${PTS_REF}" \
  -t "${IMAGE_TAG}" "${REPO_DIR}"

run_env=(-e "FORCE_TIMES_TO_RUN=${FORCE_TIMES_TO_RUN}")
if [ "${FAST}" = "1" ]; then
  # Override the pinned set (benchmark-set.sh honours PTS_TESTS) with the quick
  # tests only -- the source-compile tests are very slow under local emulation.
  run_env+=(-e "PTS_TESTS=pts/fs-mark-1.0.3 pts/node-web-tooling-1.0.1 pts/go-benchmark-1.1.4")
fi

echo "== Running scripts/benchmark.sh ${RESULT_NAME} (FAST=${FAST}) =="
# Mount the repo scripts so the latest benchmark.sh / benchmark-set.sh are used
# without rebuilding the image (install.sh was already baked into the image).
docker run --rm --platform "${PLATFORM}" \
  "${run_env[@]}" \
  -v "${REPO_DIR}/scripts:/opt/pts-scripts:ro" \
  "${IMAGE_TAG}" \
  bash /opt/pts-scripts/benchmark.sh "${RESULT_NAME}"

echo "== Done =="
