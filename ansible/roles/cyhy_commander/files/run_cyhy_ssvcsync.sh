#!/usr/bin/env bash

# A script to run cyhy-ssvcsync to get the full set of SSVC data from the most
# recent GitHub release of the CVEProject/cvelistV5 repository.
#
# The release is expected to be named in the format "CVE YYYY-MM-DD_HH00Z".
# The zip file attached to the release is expected to be named in the format
# "YYYY-MM-DD_all_CVEs_at_midnight.zip.zip".

set -o nounset
set -o errexit
set -o pipefail

# Get the recent releases for the cvelistV5 repository from the GitHub REST API.
# Since releases are returned in descending order by creation date, the most
# recent release will be the first one in the list.
RELEASES_JSON=$(
  curl --silent --user-agent "cisagov/cyhy_amis/run_cyhy_ssvcsync" \
    "https://api.github.com/repos/CVEProject/cvelistV5/releases"
)

# Check if the API request was successful
if [[ -z "$RELEASES_JSON" ]]; then
  echo "Error: Failed to retrieve releases from GitHub API" >&2
  exit 1
fi

# Find the name of the most recent release that matches the naming pattern
# "CVE YYYY-MM-DD_HH00Z"
RELEASE_NAME=$(
  echo "$RELEASES_JSON" | jq -r '.[].name' \
    | grep -E '^CVE [0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}00Z$' | head -n 1
)

# Check if a matching release was found
if [[ -z "$RELEASE_NAME" ]]; then
  echo "Error: No release found matching the expected naming pattern" >&2
  exit 1
fi

# Find the URL of the asset in the most recent release that matches the naming
# pattern "YYYY-MM-DD_all_CVEs_at_midnight.zip.zip"
ASSET_URL=$(
  echo "$RELEASES_JSON" | jq -r --arg RELEASE_NAME "$RELEASE_NAME" \
    '.[] | select(.name == $RELEASE_NAME) | .assets[] | select(.name |
    test("^[0-9]{4}-[0-9]{2}-[0-9]{2}_all_CVEs_at_midnight.zip.zip$")) |
    .browser_download_url'
)

# Check if a matching asset was found
if [[ -z "$ASSET_URL" ]]; then
  echo "Error: No asset found in the release '$RELEASE_NAME'" \
    "matching the expected naming pattern" >&2
  exit 1
fi

# Run cyhy-ssvcsync with the URL of the asset from the most recent release
/usr/local/bin/cyhy-ssvcsync "$ASSET_URL"
