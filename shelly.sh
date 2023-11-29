#!/bin/bash

DEFAULT_VALUE="sh"

display_help() {
    cat << EOF
shelly: Publish CLI Tools 🐚✨

Usage: shelly <required> [optional]

Arguments:
  required:        The required value
  optional:        The optional value
EOF
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: The $1 command is not available. Make sure it is installed."
        exit 1
    fi
}

main() {
    required=$1
    optional=${2:-$DEFAULT_VALUE}

    check_command "$optional"

    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        display_help
        exit 0
    fi

    if [ $# -lt 1 ]; then
        echo "Error: required is required."
        echo
        display_help
        exit 1
    fi

    echo "Required: $required, Optional: $optional"
}

main "$@"

