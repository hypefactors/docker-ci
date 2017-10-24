#!/bin/bash
cd "$(dirname "$0")"
. ../utils.sh

describe "Composer"

it "checks if composer is available" \
    contains "Composer version" composer --version 