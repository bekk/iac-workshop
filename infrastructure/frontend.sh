#!/usr/bin/env bash
NEEDLE="https://conduit\\.productionready\\.io/api"
REPLACEMENT=$2

# TODO: Download payload
#curl --request GET -sL \
#     --url $1 \
#     --output './yay.zip'
rm -rf payload
#unzip $1 -d payload
unzip iac-workshop-frontend.zip -d payload
grep -RiIl "$NEEDLE" payload | xargs sed -i.bak "s#$NEEDLE#$REPLACEMENT#g"
rm payload/static/js/*.bak
