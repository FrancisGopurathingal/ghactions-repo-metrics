#!/bin/bash

REPO_NAME=$1
DATE=$(date + %d%m%Y)
FILE_NAME='nol_${REPO_NAME}_${DATE}.json

# Run cloc
cloc . --json > temp.json

# Add metadata
jq --arg repo "${REPO_NAME}" --arg date ${DATE} '{repository:$repo, date: $date, metrics: .}' temp.json > $FILE_NAME

echo "Generated: ${FILE_NAME}"
