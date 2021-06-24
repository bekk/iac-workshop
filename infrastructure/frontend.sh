#!/usr/bin/env bash

# Sane(r) bash defaults
set -eou pipefail

set -x # TODO: Debugging only

FRONTEND_ZIP_URL="$1"
BACKEND_API_URL="$2"
STORAGE_ACCOUNT_NAME="$3"
STORAGE_ACCOUNT_KEY="$4"

NEEDLE="will-be-replaced-by-terraform" # defined in frontend github action
ZIP_LOCATION='./iac-workshop-frontend.zip'

curl --request GET -sL \
     --url "$FRONTEND_ZIP_URL" \
     --output $ZIP_LOCATION

rm -rf payload
unzip $ZIP_LOCATION -d payload

# Here be dragons
grep -RiIl "$NEEDLE" payload | xargs sed -i.bak "s#$NEEDLE#$BACKEND_API_URL#g"

rm -f payload/static/js/*.bak

az storage blob upload-batch \
   --account-name "$STORAGE_ACCOUNT_NAME" \
   --account-key "$STORAGE_ACCOUNT_KEY" \
   --source payload/ \
   --destination '$web'
#TODO: Remove zip
