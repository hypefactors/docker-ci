cd "$(dirname "$0")"
source ../utils.sh

describe "PHP"

it "checks if PHP 7.1 is installed" \
    contains "PHP 7.1" php -v