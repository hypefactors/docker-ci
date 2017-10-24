cd "$(dirname "$0")"
source ../utils.sh

describe "Composer"

it "checks if composer is available" \
    contains "Composer version" composer --version 