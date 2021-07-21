#!/bin/bash

goog=$(curl https://www.gstatic.com/ipranges/goog.json)

# ipv4 ranges
echo $goog | jq -r  '.prefixes[].ipv4Prefix | select( . != null ) | "route = " + .' > ./ocserv/config-per-group/google

# ipv6 ranges
# echo $goog | jq -r  '.prefixes[].ipv6Prefix | select( . != null ) | "route = " + .'

# both ipv4 and ipv6 ranges
# echo $goog | jq -r  '.prefixes[] | .ipv4Prefix // .ipv6Prefix | select( . != null ) | "route = " + .'
