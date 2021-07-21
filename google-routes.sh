#!/bin/bash

goog=$(curl https://www.gstatic.com/ipranges/goog.json)

# ipv4 ranges
echo $goog | jq -r  '.prefixes[].ipv4Prefix | select( . != null )' > google-route.txt

# ipv6 ranges
# echo $goog | jq -r  '.prefixes[].ipv6Prefix | select( . != null )'

# both ipv4 and ipv6 ranges
# echo $goog | jq -r  '.prefixes[] | .ipv4Prefix // .ipv6Prefix | select( . != null )'
