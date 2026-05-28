#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${INPUT_OUTPUT_DIR:-nol-reports}"
BRANCH="${INPUT_BRANCH:-main}"
INSTALL_CLOC="${INPUT_INSTALL_CLOC:-true}"

REPOSITORY="${GITHUB_REPOSITORY:-unknown/unknown}"
OWNER="${GITHUB_REPOSITORY_OWNER:-unknown}"
SHA="${GITHUB_SHA:-unknown}"
REF_NAME="${GITHUB_REF_NAME:-unknown}"

REPO_NAME="$(basename "$REPOSITORY")"
DATE_DDMMYYYY="$(date -u +'%d%m%Y')"

REPORT_FILE="${OUTPUT_DIR}/nol_${REPO_NAME}_${DATE_DDMMYYYY}.json"
CLOC_TEMP_FILE="$(mktemp)"

mkdir -p "$OUTPUT_DIR"

echo "Repository: ${REPOSITORY}"
echo "Branch: ${BRANCH}"
echo "Output file: ${REPORT_FILE}"

if ! command -v cloc >/dev/null 2>&1; then
  if [[ "${INSTALL_CLOC}" == "true" ]]; then
    echo "cloc not found. Installing cloc..."
    sudo apt-get update
    sudo apt-get install -y cloc
  else
    echo "ERROR: cloc is ot installed and install-cloc=false."
    exit 1
  fi
fi

echo "Running cloc..."
cloc . --json --vcs=git --exclude-dir=.git --timeout=0 --by-file-by-lang > "${CLOC_TEMP_FILE}"

cat > "${REPORT_FILE}" <<EOF
{
  "report_type": "number_of_lines",
  "repository": "${REPOSITORY}",
  "repository_id": "${REPOSITORY_ID}
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

echo "report-file=${REPORT_FILE}" >> "${GITHUB_OUTPUT}"