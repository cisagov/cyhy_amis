#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# Get current date in UTC in the format YYYY-MM-DD
CURRENT_DATE=$(date --utc +"%Y-%m-%d")

# Get two hours ago in UTC in the format HH
TWO_HOURS_AGO_HOUR=$(date --utc --date="2 hours ago" +"%H")

# Build the URL for the CVEs zip file in the GitHub release based on the
# current date and two hours ago.  Use the release from two hours ago to allow
# plenty of time for the release to be published.
RELEASE_URL="https://github.com/CVEProject/cvelistV5/releases/download/cve_${CURRENT_DATE}_${TWO_HOURS_AGO_HOUR}00Z/${CURRENT_DATE}_all_CVEs_at_midnight.zip.zip"

# Run cyhy-ssvcsync to get the full set of SSVC data from a recent (~2 hours
# prior) GitHub release. The release is expected to be named in the format
# "cve_YYYY-MM-DD_HH00Z". The zip file within the release is expected to be
# named in the format "YYYY-MM-DD_all_CVEs_at_midnight.zip.zip".
#
# NOTE: This will not work correctly if the script is run between 0000 and 0200
# UTC, but that is an acceptable limitation since the script is only intended to
# be run once per day, outside of those hours.
/usr/local/bin/cyhy-ssvcsync "$RELEASE_URL"
