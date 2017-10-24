cd "$(dirname "$0")"
source ../utils.sh

describe "Node.js"

it "checks if Node.js v8 is installed" \
    contains "v8" node -v