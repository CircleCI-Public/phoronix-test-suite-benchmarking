# Builds a local image matching the CI environment (Ubuntu 24.04 + PTS + the
# benchmark tests) so the benchmark can be run locally. The setup is done by
# scripts/install.sh -- the same script CircleCI and GitHub Actions run -- so
# there is a single source of truth. See test-benchmark.sh, which builds this
# image and runs scripts/benchmark.sh in it.

# cimg/base:current-24.04 is Ubuntu 24.04, matching the CI executors.
ARG BASE_IMAGE=cimg/base:current-24.04
FROM ${BASE_IMAGE}

# Git ref of phoronix-test-suite to install (branch or tag).
ARG PTS_REF=master

# Copy only what install.sh needs, so editing benchmark.sh / report.sh does not
# invalidate this (slow) install layer. install.sh sources benchmark-set.sh from
# its own directory.
COPY scripts/benchmark-set.sh scripts/install.sh /opt/pts-scripts/
RUN PTS_REF="${PTS_REF}" bash /opt/pts-scripts/install.sh
