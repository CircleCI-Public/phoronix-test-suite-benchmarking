#!/usr/bin/env bash
#
# Install system dependencies, the Phoronix Test Suite (from git), configure it
# for non-interactive batch runs, and install the pinned benchmark test profiles.
#
# Runs on Ubuntu 24.04 with passwordless sudo -- satisfied by the CircleCI
# executors, GitHub Actions ubuntu-24.04 runners, and the local Docker image
# built from ./Dockerfile. Env: PTS_REF (default: master),
# PTS_INSTALL_TESTS (default: true -- set false to install PTS without the
# benchmark test profiles, e.g. for the report-only results job).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/benchmark-set.sh
. "${SCRIPT_DIR}/benchmark-set.sh"

PTS_REF="${PTS_REF:-master}"
PTS_INSTALL_TESTS="${PTS_INSTALL_TESTS:-true}"

echo "== Installing system dependencies =="
DEBIAN_FRONTEND=noninteractive sudo apt-get -y update
# PTS is a PHP app (php-cli + extensions). libelf-dev/bc/bison/flex/libssl-dev
# are build-linux-kernel's build deps, which PTS does not pull on 24.04.
DEBIAN_FRONTEND=noninteractive sudo apt-get -y install \
  git \
  php-cli \
  php-xml \
  php-curl \
  php-gd \
  php-zip \
  php-fpdf \
  fonts-dejavu-core \
  libelf-dev \
  bc \
  bison \
  flex \
  libssl-dev

echo "== Installing Phoronix Test Suite (${PTS_REF}) from git =="
# PTS stopped publishing tagged .deb releases after 10.8.4 (2022), which predates
# Ubuntu 24.04. install-sh must run from the source tree and writes to /usr.
rm -rf /tmp/pts
git clone --depth 1 --branch "${PTS_REF}" \
  https://github.com/phoronix-test-suite/phoronix-test-suite.git /tmp/pts
( cd /tmp/pts && sudo ./install-sh )
rm -rf /tmp/pts

echo "== Configuring PTS for non-interactive batch runs =="
# enterprise-setup: disables anonymous usage reporting + OpenBenchmarking uploads
# and accepts the user agreement. user-config-set: batch mode, so batch-benchmark
# runs with no interactive prompts.
phoronix-test-suite enterprise-setup
phoronix-test-suite user-config-set \
  PhoronixTestSuite/Options/BatchMode/Configured=TRUE \
  PhoronixTestSuite/Options/BatchMode/SaveResults=TRUE \
  PhoronixTestSuite/Options/BatchMode/PromptForTestIdentifier=FALSE \
  PhoronixTestSuite/Options/BatchMode/PromptForTestDescription=FALSE \
  PhoronixTestSuite/Options/BatchMode/PromptSaveName=FALSE \
  PhoronixTestSuite/Options/BatchMode/OpenBrowser=FALSE \
  PhoronixTestSuite/Options/BatchMode/UploadResults=FALSE \
  PhoronixTestSuite/Options/BatchMode/RunAllTestCombinations=FALSE

# The report-only results job merges results and renders HTML; it needs the PTS
# binary but not the test profiles, so it sets PTS_INSTALL_TESTS=false to skip
# this (slow) step.
if [ "${PTS_INSTALL_TESTS}" = "true" ]; then
  echo "== Installing benchmark tests =="
  # GO111MODULE=off: go-benchmark's install builds its helpers in legacy GOPATH
  # mode, which fails on modern Go (module mode).
  # shellcheck disable=SC2086  # PTS_TESTS must word-split into separate arguments
  GO111MODULE=off phoronix-test-suite install ${PTS_TESTS}
else
  echo "== Skipping benchmark test install (PTS_INSTALL_TESTS=${PTS_INSTALL_TESTS}) =="
fi

echo "== install.sh complete =="
