#!/bin/bash

REPO="${1}"
DAYS="${2:-30}" # Defaults to 30 days if not provided

if [[ -z "$REPO" ]]; then
  echo "Usage: $0 <owner/repo> [minimum_days_old]"
  echo "Example: $0 anchore/grype 30"
  exit 1
fi

# Calculate the threshold in seconds (days * hours * minutes * seconds)
THRESHOLD_SECONDS=$(( DAYS * 24 * 60 * 60 ))

# We fetch up to 100 releases (the max per page) to ensure we look back far enough 
# for very active repositories.
API_URL="https://api.github.com/repos/${REPO}/releases?per_page=100"

# Use jq to parse the JSON array:
# 1. Filter out drafts and prereleases.
# 2. Filter for releases where (current time - published time) >= threshold.
# 3. Take the first resulting item (since GitHub returns newest first).
# 4. Extract its tag_name.
RELEASE=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
  "$API_URL" | \
  jq -r --argjson threshold "$THRESHOLD_SECONDS" '
    map(select(.tag_name | contains("rc") | not)) |
    map(select(.draft == false and .prerelease == false)) |
    map(select((now - (.published_at | fromdateiso8601)) >= $threshold)) |
    .[0].tag_name // empty
  ')

if [[ -z "$RELEASE" || "$RELEASE" == "null" ]]; then
  echo "Error: Could not find a release for $REPO older than $DAYS days." >&2
  exit 1
fi

echo "$RELEASE"