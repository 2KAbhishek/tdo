#!/bin/bash

display_help() {
    cat <<EOF
tdo: Todos and Notes, Blazingly Fast! 📃🚀

Usage: tdo [options] [arguments]

Options:
-e | --entry | e | entry:    searches for argument in notes
-f | --find  | f | find:     searches for argument in notes
-t | --todo  | t | todo:     shows all pending todos
-h | --help  | h | help:     shows this help message

Example:
# opens today's todo
tdo
# opens tommorow's todo
tdo 1
# shows all pending todos
tdo t
# open today's journal entry
tdo e
# opens day before yesterday's journal entry
tdo e -2
# opens the note for vim.md in tech dir
tdo tech/vim
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
    if [ -d ".git" ] || git rev-parse --git-dir >/dev/null 2>&1; then
        if [ -n "$(git status --porcelain)" ]; then
            timestamp=$(date +'%d %b %H:%M')
            git pull --rebase --autostash >/dev/null 2>&1 &
            git add .
            git commit -m "$timestamp" >/dev/null 2>&1 &
            git push >/dev/null 2>&1 &
        fi
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

generate_file_path() {
    offset="${1:-0}"

    year=$(date -d "$offset days" +'%Y')
    month=$(date -d "$offset days" +'%m')
    day=$(date -d "$offset days" +'%d')
    file_name="${year}-${month}-${day}.md"

    echo "$year/$month/$file_name"
}

new_todo() {
    todo_file="log/$(generate_file_path "$1")"
    template="notes/templates/todo.md"

    cd "$NOTES_DIR" || return
    mkdir -p "$(dirname "$todo_file")"
    if [ ! -f "$todo_file" ]; then
        [ -f "$template" ] && cp "$template" "$todo_file"
    fi
    $EDITOR "$todo_file"

    commit
    cd - >/dev/null || return
}

new_entry() {
    cd "$JOURNAL_DIR" || return
    entry_file="$(generate_file_path "$1")"
    timestamp=$(date +'%a, %d %b %y, %I:%M %p')

    mkdir -p "$(dirname "$entry_file")"
    if [ ! -f "$entry_file" ]; then
        cp template.md "$entry_file"
    fi

    echo -e "\n## $timestamp\n" >>"$entry_file"
    ${EDITOR:-vim} '+normal Go ' +startinsert "$entry_file"

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

main() {
    check_command "rg"
    check_command "fzf"

    case "$1" in
    -e | --entry | e | entry)
        new_entry "$2"
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
    "" | [0-9-]*)
        new_todo "$1"
        ;;
    *)
        new_note "$1"
        ;;
    esac
}

main "$@"
