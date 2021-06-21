#!/usr/bin/env bash
set -eou pipefail
URL=$1

# Request headers for the given URL, and extract the etag field
# If the command fails, exit with error message written to stderr
etag=$(curl -sfIL "$URL" | awk 'BEGIN {FS=": "}/^etag/{print $2}' | tr -d '"' | tr -d '\r' || (echo "Extraction of etag failed for $URL" >&2 && exit 1))

# Output must be in valid json
echo "{ \"etag\": \"$etag\" }"
