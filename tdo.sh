#!/bin/bash

display_help() {
    cat <<EOF
tdo: Todos and Notes, Blazingly Fast! 📃🚀

Usage: tdo <required> [optional]

Arguments:
  required:        The required value
  optional:        The optional value
EOF
}

todos() {
    cd "$NOTES_DIR" || return
    rg -l --sort created --glob '!templates/*' '\[ \]' |
        fzf --bind "enter:execute($EDITOR {})" --preview 'rg -e "\[ \]" {}'
    cd - >/dev/null || return
}

search() {
    cd "$NOTES_DIR" || return
    rg -l --sort created "$1" |
        fzf --bind "enter:execute($EDITOR {})" --preview "bat --color=always --style=grid --line-range :500 {}"
    cd - >/dev/null || return
}

check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "Error: The $1 command is not available. Make sure it is installed."
        exit 1
    fi
}

main() {
    check_command "rg"
    check_command "fzf"
    check_command "bat"

    case "$1" in
    -h | --help)
        display_help
        exit 0
        ;;
    "")
        todos
        exit 0
        ;;
    *)
        search "$1"
        ;;
    esac
}

main "$@"
