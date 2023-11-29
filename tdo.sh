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

check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "Error: The $1 command is not available. Make sure it is installed."
        exit 1
    fi
}

search() {
    cd "$NOTES_DIR" || return
    rg -l --sort created "$1" |
        fzf --bind "enter:execute($EDITOR {})" \
            --preview "bat --color=always --style=numbers --line-range :500 {}"
    cd - >/dev/null || return
}

todos() {
    cd "$NOTES_DIR" || return
    rg -l --sort created --glob '!templates/*' '\[ \]' |
        fzf --bind "enter:execute($EDITOR {})" --preview 'rg -e "\[ \]" {}'
    cd - >/dev/null || return
}

todo() {
    cd "$NOTES_DIR" || return
    year=$(date +%Y)
    month=$(date +%m)
    today=$(date +%Y-%m-%d)
    todo_file="log/$year/$month/$today.md"

    if [ ! -f "$todo_file" ]; then
        cp notes/templates/todo.md "$todo_file"
    fi

    mkdir -p "$(dirname "$todo_file")"
    $EDITOR "$todo_file"
    cd - >/dev/null || return
}

note() {
    cd "$NOTES_DIR" || return
    notes_file="notes/$1.md"

    if [ ! -f "$notes_file" ]; then
        cp notes/templates/note.md "$notes_file"
    fi
    mkdir -p "$(dirname "$notes_file")"
    $EDITOR "$notes_file"
    cd - >/dev/null || return
}

main() {
    check_command "rg"
    check_command "fzf"
    check_command "bat"

    case "$1" in
    -h | --help | h | help)
        display_help
        exit 0
        ;;
    -s | --search | s | search)
        search "$2"
        exit 0
        ;;
    -t | --todos | t | todos)
        todos
        exit 0
        ;;
    "")
        todo
        exit 0
        ;;
    *)
        note "$1"
        ;;
    esac
}

main "$@"
