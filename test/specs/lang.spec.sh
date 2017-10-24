#!/bin/bash
cd "$(dirname "$0")"
. ../utils.sh

describe "LANG"

it "checks if LANG is set to UTF8" \
    contains "en_US.UTF-8" echo $LANG