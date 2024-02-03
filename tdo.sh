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

commit_changes() {
    cd "${1-$PWD}" || return
    if [ -d ".git" ] || git rev-parse --git-dir >/dev/null 2>&1; then
        if [ -n "$(git status --porcelain)" ]; then
            timestamp=$(date +'%d %b %H:%M')
            git pull --rebase --autostash >/dev/null 2>&1 &
            git add .
            git commit -m "$timestamp" >/dev/null 2>&1 &
            git push >/dev/null 2>&1 &
        fi
    fi
    cd - >/dev/null || return
}

search() {
    root="$NOTES_DIR"
    cd "$root" || return
    rg -li --sort path "$1" |
        fzf --bind "enter:execute($EDITOR {})" \
            --preview "bat --style=numbers --color=always --line-range=:500 {} || cat {}"
    commit_changes
}

pending_todos() {
    root="${TODOS_DIR:-$NOTES_DIR}"
    cd "$root" || return
    rg -l --glob '!/templates/*' '\[ \]' |
        fzf --bind "enter:execute($EDITOR {})" --preview 'rg -e "\[ \]" {}'
    commit_changes
}

generate_file_path() {
    offset="${1:-0}"
    year=$(date -d "$offset days" +'%Y')
    month=$(date -d "$offset days" +'%m')
    day=$(date -d "$offset days" +'%d')
    file_name="${year}-${month}-${day}.md"

    echo "$year/$month/$file_name"
}

create_file() {
    file_path="$1"
    template_path="$2"

    mkdir -p "$(dirname "$file_path")"
    if [ ! -f "$file_path" ]; then
        [ -f "$template_path" ] && cp "$template_path" "$file_path"
    fi
}

add_timestamp() {
    file_path="$1"
    time_format="${2:-%a, %I:%M %p}"
    timestamp=$(date +"$time_format")
    echo -e "\n## $timestamp\n" >>"$file_path"
}

write_file() {
    file_path="$1"
    if [ -t 1 ]; then
        $EDITOR "$file_path"
        commit_changes "$(dirname "$file_path")"
    else
        echo "$file_path" && exit 0
    fi
}

new_note() {
    root="$NOTES_DIR"
    note_file="$root/notes/$1.md"
    template="$root/templates/note.md"
    create_file "$note_file" "$template"
    write_file "$note_file"
}

new_todo() {
    root="${TODOS_DIR:-$NOTES_DIR}"
    todo_file="$root/todos/$(generate_file_path "$1")"
    template="$root/templates/todo.md"
    create_file "$todo_file" "$template"
    write_file "$todo_file"
}

new_entry() {
    root="${JOURNAL_DIR:-$NOTES_DIR}"
    entry_file="$root/entries/$(generate_file_path "$1")"
    template="$root/templates/entry.md"
    create_file "$entry_file" "$template"
    add_timestamp "$entry_file"
    write_file "$entry_file"
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
