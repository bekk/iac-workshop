#!/usr/bin/env bash
# Sane(r) bash defaults
set -eou pipefail

FRONTEND_ZIP_URL="$1"
BACKEND_API_URL="$2"
STORAGE_ACCOUNT_NAME="$3"
STORAGE_ACCOUNT_KEY="$4"

NEEDLE="will-be-replaced-by-terraform" # defined in frontend github action
ZIP_LOCATION='./iac-workshop-frontend.zip'

# Get the frontend release zip and write it to the given location
curl --request GET -sL \
     --url "$FRONTEND_ZIP_URL" \
     --output $ZIP_LOCATION

# Remove the previous payload, if it exists, and unzip the newly downloaded zip
rm -rf payload
unzip $ZIP_LOCATION -d payload

# Here be dragons
# Grep outputs the file names of all non-binary files that contains the string
# we're looking for. xargs gives these filenames as arguments to the sed command.
# sed makes a backup of {filename} to {filename}.bak, and does the string
# substitution in-place. Note that '/' is the usual separation character, but
# here '#' is used since the strings can contain '/'. The backup file are not
# really needed and are therefore immediately deleted. We have to do this
# because the sed command line utility has multiple implementations, and
# especially the default macOS implementation has some weird behavior. This
# way *should* work pretty well cross-platform.
grep -RiIl "$NEEDLE" payload | xargs sed -i.bak "s#$NEEDLE#$BACKEND_API_URL#g"
rm -f payload/static/js/*.bak

# Use the az CLI to upload all files to the storage account, in the '$web' container.
az storage blob upload-batch \
   --account-name "$STORAGE_ACCOUNT_NAME" \
   --account-key "$STORAGE_ACCOUNT_KEY" \
   --source payload/ \
   --destination '$web'

rm $ZIP_LOCATION
rm -rf payload
