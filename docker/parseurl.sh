#!/bin/sh
# Referenced and tweaked from http://stackoverflow.com/questions/6174220/parse-url-in-shell-script#6174447

url="$1"
prefix="$2"
proto="$(echo "$url" | grep :// | sed -e 's,^\(.*\)://.*,\1,g')"
# remove the protocol
workurl="$(echo "$url" |sed -e "s,^$proto://,,")"
# extract the user (if any)
userpass="$(echo "$workurl" | grep @ | cut -d@ -f1)"
pass="$(echo "$userpass"| grep : | cut -d: -f2)"
if [ -n "$pass" ]; then
  user="$(echo "$userpass" | grep : | cut -d: -f1)"
else
    user="$userpass"
fi

# extract the host
hostport="$(echo "$workurl" |sed -e "s,$userpass@,," | cut -d/ -f1)"
# by request - try to extract the port
port="$(echo "$hostport" | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
host="$(echo "$hostport" | cut -d: -f1)"
# extract the path (if any)
path="/$(echo "$workurl" | grep / | cut -d/ -f2-)"
name="$(echo "$workurl" | grep / | cut -d/ -f2-)"

echo "${prefix}_URL=\"$url\""
echo "${prefix}_PROTO=\"$proto\""
echo "${prefix}_USER=\"$user\""
echo "${prefix}_PASS=\"$pass\""
echo "${prefix}_HOST=\"$host\""
echo "${prefix}_PORT=\"$port\""
echo "${prefix}_PATH=\"$path\""
echo "${prefix}_NAME=\"$name\""

