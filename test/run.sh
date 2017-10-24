#!/bin/bash
set -eo pipefail

[ "$DEBUG" ] && set -x

# Set current working directory to the directory of the script
cd "$(dirname "$0")"

# Load the utilities
. ./utils.sh

yellowText "Testing $dockerImage ...\n"

if ! docker inspect "$dockerImage" &> /dev/null; then
    fail 'Image does not exist!'
    false
fi

## TESTS
status=1

for file in ./specs/*.spec.sh
do
    result=$(sh $file)
    printf "$result"

    # Check if any of the tests failed
    if echo "$result" | grep -q "FAIL"; then
        status=0
    fi
done

if [ "$status" -eq "1" ]; then
    greenText "\nSUCCESS"
else
    redText "\nFAILED" && exit 1
fi
