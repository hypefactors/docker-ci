#!/bin/bash
cd "$(dirname "$0")"
. ../utils.sh

describe "PHP"

it "checks if PHP 7.1 is installed" \
    contains "PHP 7.1" php -v