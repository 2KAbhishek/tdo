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

commit() {
    if [ -n "$(git status --porcelain)" ]; then
        timestamp=$(date +'%a, %d %b %y, %I:%m %p')
        git pull --rebase --autostash >/dev/null 2>&1 &
        git add .
        git commit -m "$timestamp" >/dev/null 2>&1 &
        git push >/dev/null 2>&1 &
    fi
}

search() {
    cd "$NOTES_DIR" || return

    rg -li --sort path "$1" |
        fzf --bind "enter:execute($EDITOR {})" \
            --preview "bat --style=numbers --color=always --line-range=:500 {} || cat {}"

    commit
    cd - >/dev/null || return
}

pending_todos() {
    cd "$NOTES_DIR" || return
    rg -l --glob '!*/templates/*' '\[ \]' |
        fzf --bind "enter:execute($EDITOR {})" --preview 'rg -e "\[ \]" {}'

    commit
    cd - >/dev/null || return
}

new_todo() {
    cd "$NOTES_DIR" || return
    year=$(date +'%Y')
    month=$(date +'%m')
    file_name=$(date +'%Y-%m-%d.md')
    todo_file="log/$year/$month/$file_name"

    mkdir -p "$(dirname "$todo_file")"
    if [ ! -f "$todo_file" ]; then
        template="notes/templates/todo.md"
        [ -f "$template" ] && cp "$template" "$todo_file"
    fi
    $EDITOR "$todo_file"

    commit
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

    commit
    cd - >/dev/null || return
}

new_entry() {
    cd "$ENTRY_DIR" || return
    year=$(date +'%Y')
    month=$(date +'%m')
    file_name=$(date +'%Y-%m-%d.md')
    timestamp=$(date +'%a, %d %b %y, %I:%m %p')
    entry_file="$year/$month/$file_name"

    if [ ! -f "$entry_file" ]; then
        mkdir -p "$year/$month"
        cp template.md "$entry_file"
    fi

    echo -e "\n## $timestamp\n" >>"$entry_file"
    ${EDITOR:-vim} '+normal Go ' +startinsert "$entry_file"

    commit
    cd - >/dev/null || return
}

main() {
    check_command "rg"
    check_command "fzf"

    case "$1" in
    -e | --entry | e | entry)
        new_entry
        ;;
    -f | --find | f | find)
        search "$2"
        ;;
    -h | --help | h | help)
        display_help
        ;;
    -t | --todo | t | todo)
        pending_todos
        ;;
    "")
        new_todo
        ;;
    *)
        new_note "$1"
        ;;
    esac
}

main "$@"
