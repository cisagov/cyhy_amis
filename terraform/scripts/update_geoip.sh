#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# Print usage information and exit.
function usage {
  echo "Usage:"
  echo "  ${0##*/} [options]"
  echo
  echo "Options:"
  echo "  -h, --help         Show the help message."
  echo "  -p, --remote-path  Path on the remote host to use."
  echo "  -t, --target-host  Host to update."
  exit "$1"
}

target_name="database1.prod-a.cyhy"
target_path="/usr/local/share/GeoIP"

while (("$#")); do
  case "$1" in
    -h | --help)
      usage 0
      ;;
    -p | --remote-path)
      target_path="$1"
      shift 1
      ;;
    -t | --target-host)
      target_name="$1"
      shift 1
      ;;
    -*)
      usage 1
      ;;
  esac
done

maxmind_url_format="%s?edition_id=%s&suffix=%s&license_key=%s"
maxmind_url_base="https://download.maxmind.com/app/geoip_download"
maxmind_edition="GeoIP2-City"
maxmind_suffix_file="tar.gz"
maxmind_suffix_checksum="tar.gz.md5"
maxmind_license_key=$(aws ssm get-parameter \
  --output text \
  --name "/cyhy/core/geoip/license_key" \
  --with-decryption \
  | awk -F"\t" '{print $6;}')

# Disable SC2059 "Don't use variables in the printf format string." check
# because the variable contains a printf format string.
# shellcheck disable=SC2059
remote_url_md5sum=$(printf "$maxmind_url_format" "$maxmind_url_base" "$maxmind_edition" "$maxmind_suffix_checksum" "$maxmind_license_key")
# shellcheck disable=SC2059
remote_url_targz=$(printf "$maxmind_url_format" "$maxmind_url_base" "$maxmind_edition" "$maxmind_suffix_file" "$maxmind_license_key")

geoip_remote_md5="$(curl -s "$remote_url_md5sum")"
geoip_local_file="$(printf "%s.%s" "$maxmind_edition" "$maxmind_suffix_file")"

curl -s --output "$geoip_local_file" "$remote_url_targz"

geoip_local_md5=$(md5sum "$geoip_local_file" | awk '{print $1;}')

if [ "$geoip_remote_md5" != "$geoip_local_md5" ]; then
  echo "md5sum mismatch!"
  echo "Remote md5sum: $geoip_remote_md5"
  echo "Local File md5sum: $geoip_local_md5"
  rm "$geoip_local_file"
  exit
fi

# Copy the file to the remote host while preserving the file's timestamps (-p)
scp -p "$geoip_local_file" "$target_name":
# Disable SC22029 "Note that, unescaped, this expands on the client side." check
# because we are populating values from the client side to use on the remote
# side.
# shellcheck disable=SC2029
ssh "$target_name" "sudo cp $geoip_local_file $target_path; cd $target_path; sudo tar -xzf $geoip_local_file --strip-components=1"
