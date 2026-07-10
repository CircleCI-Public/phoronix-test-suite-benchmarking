#!/usr/bin/env bash
#
# Best-effort fetch of the GitHub Actions benchmark result for the current commit
# so the CircleCI report job can merge the x86 (github-hosted) run alongside the
# gen1/gen2/gen3 generations.
#
# The two CI systems run independently off the same push, so this polls for the
# GHA `benchmark` workflow run at this commit, waits for it to finish, and
# downloads its `result-x86` artifact into the PTS test-results dir.
#
# It is intentionally best-effort: if the run is missing, still running past the
# timeout, didn't succeed, or no token is configured, it logs why and exits 0 so
# the report is still produced from the CircleCI results alone.
#
# Auth: needs GH_TOKEN or GITHUB_TOKEN (actions:read on this repo) in the
# environment -- set it as a CircleCI project/context env var. `gh` must already
# be on PATH (installed via the circleci/github-cli orb's gh/install).
#
# Env overrides (all default to CircleCI-provided values):
#   GHA_REPO           owner/repo             (default: $CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME)
#   GHA_SHA            commit to match        (default: $CIRCLE_SHA1)
#   GHA_WORKFLOW       workflow name/file     (default: benchmark)
#   GHA_ARTIFACT       artifact to download   (default: result-x86)
#   GHA_RESULT_NAME    PTS result dir name    (default: x86)
#   GHA_NORUN_GRACE    seconds to wait for a run to *appear*   (default: 180)
#   GHA_WAIT_TIMEOUT   seconds to wait once a run is running   (default: 5400)
#   GHA_POLL_INTERVAL  seconds between polls                   (default: 30)
#
set -uo pipefail

REPO="${GHA_REPO:-${CIRCLE_PROJECT_USERNAME:-}/${CIRCLE_PROJECT_REPONAME:-}}"
SHA="${GHA_SHA:-${CIRCLE_SHA1:-}}"
WORKFLOW="${GHA_WORKFLOW:-benchmark}"
ARTIFACT="${GHA_ARTIFACT:-result-x86}"
RESULT_NAME="${GHA_RESULT_NAME:-x86}"
TIMEOUT="${GHA_WAIT_TIMEOUT:-5400}"
GRACE="${GHA_NORUN_GRACE:-180}"
INTERVAL="${GHA_POLL_INTERVAL:-30}"

DEST="${HOME}/.phoronix-test-suite/test-results"

# Best-effort: log why we're giving up and exit 0 so the report still runs.
skip() {
  echo "== Skipping GHA result fetch: $* =="
  echo "   The report will be built from the CircleCI results only."
  exit 0
}

[ -n "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ] || skip "no GH_TOKEN / GITHUB_TOKEN set"
[ -n "${SHA}" ] || skip "commit SHA unknown (CIRCLE_SHA1 unset)"
case "${REPO}" in ?*/?*) : ;; *) skip "repo slug unknown (${REPO})" ;; esac
command -v gh >/dev/null 2>&1 || skip "gh CLI not found on PATH"

echo "== Waiting for GitHub Actions '${WORKFLOW}' run at ${SHA} (repo ${REPO}; up to ${GRACE}s to appear, then ${TIMEOUT}s while running) =="

# Two separate waits: a short grace for a run to *appear* (GHA registers within
# seconds of a push, so if none shows up it isn't coming -- don't burn the full
# timeout on branches GHA doesn't build), then a generous timeout once a run is
# seen in progress.
run_id=""; status=""; conclusion=""
seen_run=0
start=${SECONDS}
while :; do
  # Newest run matching this commit, as TSV: databaseId, status, conclusion.
  # `first // {}` yields empty fields when no run exists for the commit yet.
  line="$(
    gh run list -R "${REPO}" --workflow "${WORKFLOW}" --limit 50 \
      --json databaseId,headSha,status,conclusion \
      -q "map(select(.headSha == \"${SHA}\")) | first // {} | [.databaseId, .status, .conclusion] | @tsv" \
      2>/dev/null || true
  )"
  IFS=$'\t' read -r run_id status conclusion <<<"${line}"

  if [ -z "${run_id}" ]; then
    echo "   no run for this commit yet..."
  elif [ "${status}" != "completed" ]; then
    seen_run=1
    echo "   run ${run_id} status=${status}..."
  else
    echo "   run ${run_id} completed (conclusion=${conclusion})."
    break
  fi

  elapsed=$(( SECONDS - start ))
  if [ "${seen_run}" -eq 1 ]; then
    [ "${elapsed}" -lt "${TIMEOUT}" ] || skip "timed out after ${TIMEOUT}s waiting for in-progress run ${run_id}"
  else
    [ "${elapsed}" -lt "${GRACE}" ] || skip "no GHA run found for ${SHA} within ${GRACE}s"
  fi
  sleep "${INTERVAL}"
done

[ "${conclusion}" = "success" ] || skip "GHA run ${run_id} did not succeed (conclusion=${conclusion})"

echo "== Downloading '${ARTIFACT}' from run ${run_id} =="
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

gh run download "${run_id}" -R "${REPO}" -n "${ARTIFACT}" -D "${tmp}" \
  || skip "could not download artifact '${ARTIFACT}' (not present?)"

# Locate the PTS result dir inside the download by finding its composite.xml,
# so this is robust to however gh nests the extracted artifact.
composite="$(find "${tmp}" -type f -name composite.xml -print -quit 2>/dev/null || true)"
[ -n "${composite}" ] || skip "no composite.xml in downloaded artifact"
src="$(dirname "${composite}")"

mkdir -p "${DEST}/${RESULT_NAME}"
cp -r "${src}/." "${DEST}/${RESULT_NAME}/"
echo "== Staged GHA result as '${RESULT_NAME}' in ${DEST} =="
