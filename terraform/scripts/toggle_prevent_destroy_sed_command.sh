#!/bin/sh

# Usage:
#   toggle_prevent_destroy_command.sh <regex> <file> <tmp_file>
#
# We need this script because the file redirection doesn't play nice
# with find's exec clause.  See, for example, here:
# https://stackoverflow.com/questions/15030563/redirecting-stdout-with-find-exec-and-without-creating-new-shell

regex=$1
file=$2
tmp_file=$3

sed "$regex" "$file" > "$tmp_file"
cp "$tmp_file" "$file"
