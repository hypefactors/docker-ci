#!/bin/bash
dockerImage="hypefactors/docker-ci:latest"

greenText () {
    printf "\033[0;32m$1\033[0m\n"
}

redText () {
    printf "\033[0;31m$1\033[0m\n"
}

yellowText () {
    printf "\033[0;33m$1\033[0m\n"
}

# Specs
contains () {
    expected=$1
    shift
    cmd="$*"

    if docker run $dockerImage $cmd | grep -q "$expected"; then
        return 1
    else
        return 0
    fi
}

describe () {
    yellowText "\nSPEC: $1"
}

it () {
    label=$1
    func=$2
    shift 
    shift

    # Execute the function
    $func "$@"

    # Inspect the result
    result=$?

    if [ "$result" -eq "1" ]; then
        pass "$label"
    else
        fail "$label"
    fi
}

# Results
pass () {
    greenText "\t- PASS: $1"
}

fail () {
    redText "\t- FAIL: $1"
}