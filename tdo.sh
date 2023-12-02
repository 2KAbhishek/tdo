#!/bin/bash

display_help() {
    cat <<EOF
tdo: Todos and Notes, Blazingly Fast! 📃🚀

Usage: tdo [options] [arguments]

Options:
-f | --find | f | find:    searches for argument in notes
-t | --todo | t | todo:    shows all pending todos
-h | --help | h | help:    shows this help message

Example:
# opens today's todo file
tdo
# opens the note for vim in tech dir
tdo tech/vim
# shows all pending todos
tdo t
# searches for neovim in all notes
tdo f neovim
# review all notes
tdo f
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
    rg -li --sort path "$1" |
        fzf --bind "enter:execute($EDITOR {})" \
            --preview "bat --style=numbers --color=always --line-range=:500 {} || cat {}"
    cd - >/dev/null || return
}

pending_todos() {
    cd "$NOTES_DIR" || return
    rg -l --glob '!*/templates/*' '\[ \]' |
        fzf --bind "enter:execute($EDITOR {})" --preview 'rg -e "\[ \]" {}'
    cd - >/dev/null || return
}

new_todo() {
    cd "$NOTES_DIR" || return
    year=$(date +%Y)
    month=$(date +%m)
    today=$(date +%Y-%m-%d)
    todo_file="log/$year/$month/$today.md"

    mkdir -p "$(dirname "$todo_file")"
    if [ ! -f "$todo_file" ]; then
        template="notes/templates/todo.md"
        [ -f "$template" ] && cp "$template" "$todo_file"
    fi
    $EDITOR "$todo_file"
    cd - >/dev/null || return
}

new_note() {
    cd "$NOTES_DIR" || return
    notes_file="notes/$1.md"

    mkdir -p "$(dirname "$notes_file")"
    if [ ! -f "$notes_file" ]; then
        template="notes/templates/note.md"
        [ -f "$template" ] && cp "$template" "$notes_file"
    fi
    $EDITOR "$notes_file"
    cd - >/dev/null || return
}

main() {
    check_command "rg"
    check_command "fzf"

    case "$1" in
    -h | --help | h | help)
        display_help
        exit 0
        ;;
    -f | --find | f | find)
        search "$2"
        exit 0
        ;;
    -t | --todo | t | todo)
        pending_todos
        exit 0
        ;;
    "")
        new_todo
        exit 0
        ;;
    *)
        new_note "$1"
        ;;
    esac
}

main "$@"
