#!/bin/sh

if [ "$#" != 1 ]; then
    echo "Usage: $0 <core-version>" 1>&2
    exit 1
fi

if [ ! -r "$(dirname $0)/token" ]; then
    echo "Create an API token on github with the 'deployment' privilege and" 1>&2
    echo "put it into '$(dirname $0)/token'." 1>&2
    exit 1
fi

curl -H "Authorization: token $(head -c 40 "$(dirname $0)/token")" \
     -H "Content-Type: application/json" \
     --data '{"ref":"action-test","required_contexts":[],"payload":{"coreversion":"'"$1"'"}}' \
     https://api.github.com/repos/pmconrad/bitshares-gitian/deployments

