#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/repo-metrics.conf"
TEMP_FILE=""

cleanup() {
  if [[ -n "${TEMP_FILE}" && -f "${TEMP_FILE}" ]]; then
    rm -f "${TEMP_FILE}"
  fi
}
trap cleanup EXIT

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

# Load shared configuration defaults
if [[ ! -f "${CONFIG_FILE}" ]]; then
  fail "configuration file not found: ${CONFIG_FILE}"
fi

# shellcheck source=/dev/null
source "${CONFIG_FILE}"

OUTPUT_DIR="${INPUT_OUTPUT_DIR:-${DEFAULT_OUTPUT_DIR:-loc-reports}}"
BRANCH="${INPUT_BRANCH:-${DEFAULT_BRANCH:-main}}"
INSTALL_CLOC="${INPUT_INSTALL_CLOC:-true}"

REPOSITORY="${GITHUB_REPOSITORY:-unknown/unknown}"
OWNER="${GITHUB_REPOSITORY_OWNER:-unknown}"
SHA="${GITHUB_SHA:-unknown}"

REPO_NAME="$(basename "${REPOSITORY}")"
DATE_DDMMYYYY="$(date -u +'%d%m%Y')"
REPORT_FILE="${OUTPUT_DIR}/loc_${REPO_NAME}_${DATE_DDMMYYYY}.json"
TEMP_FILE="$(mktemp)"

if [[ -z "${CLOC_STABLE_VERSION:-}" ]]; then
  fail "CLOC_STABLE_VERSION is not set in ${CONFIG_FILE}"
fi

mkdir -p "${OUTPUT_DIR}"

echo "Repository: ${REPOSITORY}"
echo "Branch: ${BRANCH}"
echo "Output file: ${REPORT_FILE}"
echo "Pinned cloc version: ${CLOC_STABLE_VERSION}"

if [[ "${INSTALL_CLOC}" != "true" ]]; then
  fail "install-cloc=false but cloc installation is required for this action."
fi

echo "Updating apt package index..."
sudo apt-get update -qq

echo "Checking available cloc versions..."
if ! apt-cache madison cloc | awk '{ print $3 }' | grep -Fxq "${CLOC_STABLE_VERSION}"; then
  fail "cloc version ${CLOC_STABLE_VERSION} is not available in apt repositories."
fi

echo "Installing cloc version ${CLOC_STABLE_VERSION}..."
if ! sudo apt-get install -y "cloc=${CLOC_STABLE_VERSION}"; then
  fail "Failed to install cloc=${CLOC_STABLE_VERSION}."
fi

INSTALLED_CLOC_VERSION="$(dpkg-query -W -f='${Version}' cloc 2>/dev/null || true)"
if [[ "${INSTALLED_CLOC_VERSION}" != "${CLOC_STABLE_VERSION}" ]]; then
  fail "Installed cloc version does not match pinned version. Expected: ${CLOC_STABLE_VERSION}, installed: ${INSTALLED_CLOC_VERSION:-none}"
fi

CLOC_VERSION="$(cloc --version | head -n 1)"
echo "Installed cloc version: ${CLOC_VERSION}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "Not inside a git repository."
fi

echo "Ensuring repository is on branch ${BRANCH}..."
if ! git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  echo "Branch ${BRANCH} not available locally. Fetching from origin..."
  if ! git fetch --quiet --depth=1 origin "${BRANCH}"; then
    fail "Unable to fetch branch ${BRANCH}."
  fi
fi

if ! git checkout --quiet "${BRANCH}" 2>/dev/null; then
  if ! git checkout --quiet -B "${BRANCH}" "origin/${BRANCH}"; then
    fail "Unable to checkout branch ${BRANCH}."
  fi
fi

if git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
  git reset --hard "origin/${BRANCH}" >/dev/null
fi

echo "Running cloc..."
cloc . --json --vcs=git --timeout=0 --by-file-by-lang --skip-uniqueness > "${TEMP_FILE}"

cat > "${REPORT_FILE}" <<EOF
{
  "report_type": "Lines of Code (LOC) Report",
  "repository": "${REPOSITORY}",
  "repository_name": "${REPO_NAME}",
  "owner": "${OWNER}",
  "branch": "${BRANCH}",
  "commit_sha": "${SHA}",
  "generated_at_utc": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "tool": {
    "name": "cloc",
    "version": "${CLOC_VERSION}"
  },
  "cloc": $(cat "${TEMP_FILE}")
}
EOF

echo "Generated report:"
ls -lh "${REPORT_FILE}"
cat "${REPORT_FILE}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "report-file=${REPORT_FILE}" >> "${GITHUB_OUTPUT}"
fi
