#!/bin/bash

INTERACTIVE=false
if [ -t 1 ]; then
    INTERACTIVE=true
fi

display_help() {
    cat <<EOF
tdo: Fast & Simple Note Taking! 📃🚀

Usage: tdo [command | note_path | offset]

Commands:
-c | --commit | c | commit  commits changes in the argument directory
-e | --entry  | e | entry   creates a new journal entry, accepts offset
-f | --find   | f | find    searches for argument term in notes
-n | --note   | n | note    creates a new draft note with timestamp title
-t | --todo   | t | todo    shows all pending todos
-h | --help   | h | help    shows this help message

Example:
# open today's todo
tdo
# open tomorrow's todo
tdo 1
# open or create the note tech/vim.md
tdo tech/vim
# creates a new draft note
tdo n
# open today's journal entry
tdo e
# open day before yesterday's journal entry
tdo e -2
# search for neovim in all notes
tdo f neovim
# review all notes
tdo f
# show all pending todos
tdo t

For more information, visit https://github.com/2kabhishek/tdo
EOF
}

config_setup() {
    local config_file="$HOME/.config/tdorc"
    [ -f "$config_file" ] && source "$config_file"
    add_entry_timestamp="${ADD_ENTRY_TIMESTAMP:-true}"
    add_new_note_timestamp="${ADD_NEW_NOTE_TIMESTAMP:-false}"
    filename_as_title="${FILE_NAME_AS_TITLE:-false}"
    entry_timestamp_format="${ENTRY_TIMESTAMP_FORMAT:-"## %a, %I:%M %p"}"
    note_timestamp_format="${NOTE_TIMESTAMP_FORMAT:-"## %a. %b %d, %Y - %I:%M %p"}"
}

check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "Error: The $1 command is not available. Make sure it is installed."
        exit 1
    fi
}

check_env() {
    if [ -z "${!1}" ]; then
        echo "Error: The $1 environment variable is not set. Run the install script first."
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
        fi
    fi
    cd - >/dev/null || return
}

generate_file_path() {
    offset="${1:-0}"
    date_cmd="date"
    if [ "$(uname)" = "Darwin" ]; then
        check_command "gdate"
        date_cmd="gdate"
    fi
    year=$($date_cmd -d "$offset days" +'%Y')
    month=$($date_cmd -d "$offset days" +'%m')
    day=$($date_cmd -d "$offset days" +'%d')
    file_name="${year}-${month}-${day}.md"
    echo "$year/$month/$file_name"
}

create_file() {
    file_path="$1"
    template_path="$2"

    if [ ! -f "$file_path" ]; then
        mkdir -p "$(dirname "$file_path")"
        [ -f "$template_path" ] && cp "$template_path" "$file_path"
    fi
}

add_timestamp() {
    file_path="$1"
    time_format="${2:-## %a, %I:%M %p}"
    timestamp=$(date +"$time_format")
    echo -e "\n$timestamp\n" >>"$file_path"
}

write_file() {
    file_path="$1"
    root="$2"

    if $INTERACTIVE; then
        cd "$root" || return
        "$EDITOR" "$file_path"
        commit_changes "$(dirname "$file_path")"
    else
        echo "$file_path" && exit 0
    fi
}

find_note() {
    root="$NOTES_DIR"

    local todo_cmd=''
    if [ "$EDITOR" = "vim" ] || [ "$EDITOR" = "nvim" ]; then
        todo_cmd="+'/$1' +'norm! n'"
    fi
    local editor="$EDITOR $todo_cmd"

    if $INTERACTIVE; then
        cd "$root" || return
        rg -li --sort path "$1" | sort |
            fzf --bind "enter:execute($editor {})" \
                --preview "bat --style=numbers --color=always --line-range=:500 {} || cat {}"
        commit_changes
    else
        rg -li --sort path "$1" "$root"
    fi
}

pending_todos() {
    local todo_cmd=''
    if [ "$EDITOR" = "vim" ] || [ "$EDITOR" = "nvim" ]; then
        todo_cmd="+'/ ]' +'norm! n'"
    fi
    local editor="$EDITOR $todo_cmd"

    root="${TODOS_DIR:-$NOTES_DIR}"

    if $INTERACTIVE; then
        cd "$root" || return
        rg -l --glob '!/templates/*' '\[ \]' | sort |
            fzf --bind "enter:execute($editor {})" --preview 'rg -e "\[ \]" {}'
        commit_changes
    else
        rg -l --glob '!/templates/*' '\[ \]' "$root"
    fi
}

new_note() {
    root="$NOTES_DIR"
    note_file="$root/notes/$1.md"
    template="$root/templates/note.md"
    if [ ! -f "$note_file" ]; then
        create_file "$note_file" "$template"
        $filename_as_title && echo -e "# $1" >>"$note_file"
        $add_new_note_timestamp && add_timestamp "$note_file" "$note_timestamp_format"
    fi
    write_file "$note_file" "$root"
}

draft_note() {
    title='drafts/'$(date +'%m-%d-%H-%M-%S')
    new_note "$title"
}

new_todo() {
    root="${TODOS_DIR:-$NOTES_DIR}"
    todo_file="$root/todos/$(generate_file_path "$1")"
    template="$root/templates/todo.md"
    create_file "$todo_file" "$template"
    write_file "$todo_file" "$root"
}

new_entry() {
    root="${JOURNAL_DIR:-$NOTES_DIR}"
    entry_file="$root/entries/$(generate_file_path "$1")"
    template="$root/templates/entry.md"
    create_file "$entry_file" "$template"
    $add_entry_timestamp && add_timestamp "$entry_file" "$entry_timestamp_format"
    write_file "$entry_file" "$root"
}

find_or_create_note() {
    root="$NOTES_DIR"
    note_file="$root/notes/$1.md"
    template="$root/templates/note.md"
    notes=$(find "$root" -type f -not -path '*/\.*' -iname "*$1*")

    if [ -z "$notes" ]; then
        new_note "$1"
    else
        if $INTERACTIVE; then
            cd "$root" || return
            if [ "$(echo "$notes" | wc -l)" -eq 1 ]; then
                $EDITOR "$notes"
            else
                find "$root" -type f -not -path '*/\.*' -iname "*$1*" | sed "s|^$PWD/||" | sort |
                    fzf --bind "enter:execute($EDITOR {})" \
                        --bind "ctrl-n:execute(cp $template $note_file && $EDITOR $note_file)" \
                        --header "Ctrl-n: Create '$1.md'" \
                        --preview "bat --style=numbers --color=always --line-range=:500 {} || cat {}"
            fi
            commit_changes
        else
            echo "$notes"
        fi
    fi
}

main() {
    check_command "rg"
    check_command "fzf"
    check_env "NOTES_DIR"
    config_setup

    case "$1" in
    -c | --commit | c | commit) commit_changes "$(dirname "$2")" ;;
    -e | --entry | e | entry) new_entry "$2" ;;
    -f | --find | f | find) find_note "$2" ;;
    -h | --help | h | help) display_help ;;
    -n | --note | n | note) draft_note ;;
    -t | --todo | t | todo) pending_todos ;;
    "" | [0-9-]*) new_todo "$1" ;;
    *) find_or_create_note "$1" ;;
    esac
}

main "$@"
