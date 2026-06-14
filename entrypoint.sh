#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/repo-metrics.conf"

# Load shared configuration defaults
if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "ERROR: configuration file not found: ${CONFIG_FILE}"
  exit 1
fi

# shellcheck source=/dev/null
source "${CONFIG_FILE}"

OUTPUT_DIR="${INPUT_OUTPUT_DIR:-${DEFAULT_OUTPUT_DIR:-loc-reports}}"
BRANCH="${INPUT_BRANCH:-${DEFAULT_BRANCH:-main}}"
INSTALL_CLOC="${INPUT_INSTALL_CLOC:-true}"

REPOSITORY="${GITHUB_REPOSITORY:-unknown/unknown}"
OWNER="${GITHUB_REPOSITORY_OWNER:-unknown}"
SHA="${GITHUB_SHA:-unknown}"
REF_NAME="${GITHUB_REF_NAME:-unknown}"
REPOSITORY_ID="${INPUT_REPOSITORY_ID:-unknown}"

REPO_NAME="$(basename "$REPOSITORY")"
DATE_DDMMYYYY="$(date -u +'%d%m%Y')"
REPORT_FILE="${OUTPUT_DIR}/loc_${REPO_NAME}_${DATE_DDMMYYYY}.json"
CLOC_TEMP_FILE="$(mktemp)"

if [[ -z "${CLOC_STABLE_VERSION:-}" ]]; then
  echo "ERROR: CLOC_STABLE_VERSION is not set in ${CONFIG_FILE}"
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

echo "Repository: ${REPOSITORY}"
echo "Branch: ${BRANCH}"
echo "Output file: ${REPORT_FILE}"
echo "Pinned cloc version: ${CLOC_STABLE_VERSION}"

if [[ "${INSTALL_CLOC}" != "true" ]]; then
  echo "ERROR: install-cloc=false but cloc installation is required for this action."
  exit 1
fi

echo "Updating apt package index..."
sudo apt-get update -qq

echo "Checking available cloc versions..."
if ! apt-cache madison cloc | awk '{ print $3 }' | grep -Fxq "${CLOC_STABLE_VERSION}"; then
  echo "ERROR: cloc version ${CLOC_STABLE_VERSION} is not available in apt repositories."
  echo "Please notify the repository owner ${OWNER} and update ${CONFIG_FILE} with a valid stable version."
  exit 1
fi

echo "Installing cloc version ${CLOC_STABLE_VERSION}..."
sudo apt-get install -y "cloc=${CLOC_STABLE_VERSION}" || {
  echo "ERROR: Failed to install cloc=${CLOC_STABLE_VERSION}."
  exit 1
}

INSTALLED_CLOC_VERSION="$(dpkg-query -W -f='${Version}' cloc 2>/dev/null || true)"
if [[ "${INSTALLED_CLOC_VERSION}" != "${CLOC_STABLE_VERSION}" ]]; then
  echo "ERROR: Installed cloc version does not match pinned version."
  echo "Expected: ${CLOC_STABLE_VERSION}, installed: ${INSTALLED_CLOC_VERSION:-none}"
  exit 1
fi

echo "Installed cloc version: $(cloc --version | head -n 1)"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: Not inside a git repository."
  exit 1
fi

echo "Ensuring repository is on branch ${BRANCH}..."
if ! git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  echo "Branch ${BRANCH} not available locally. Fetching from origin..."
  git fetch origin "${BRANCH}:${BRANCH}" --depth=1 2>/dev/null || git fetch origin "${BRANCH}"
fi

git checkout "${BRANCH}"
if git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
  git reset --hard "origin/${BRANCH}"
fi

echo "Running cloc..."
cloc . --json --exclude-dir=.git --timeout=0 --by-file-by-lang --skip-uniqueness > "${CLOC_TEMP_FILE}"

cat > "${REPORT_FILE}" <<EOF
{
  "report_type": "Lines of Code",
  "repository": "${REPOSITORY}",
  "repository_id": "${REPOSITORY_ID}",
  "repository_name": "${REPO_NAME}",
  "owner": "${OWNER}",
  "branch": "${BRANCH}",
  "actual_ref_name": "${REF_NAME}",
  "commit_sha": "${SHA}",
  "generated_at_utc": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "tool": {
    "name": "cloc",
    "version": "$(cloc --version | head -n 1)"
  },
  "cloc": $(cat "${CLOC_TEMP_FILE}")
}
EOF

rm -f "${CLOC_TEMP_FILE}"

echo "Generated report:"
ls -lh "${REPORT_FILE}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "report-file=${REPORT_FILE}" >> "${GITHUB_OUTPUT}"
fi
