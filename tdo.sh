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
    # List of variable names to check
    local env_vars=("TIMESTAMP_ENTRY" "TIMESTAMP_NEWNOTE" "ENTRY_TIMESTAMP" "NOTE_TIMESTAMP" "FILE_NAME_AS_TITLE")

    # Check if any of the variables are set as environment variables
    local env_variables_set=false
    for var in "${env_vars[@]}"; do
        if [ ! -z "${!var}" ]; then
            env_variables_set=true
            break
        fi
    done

    # Function to source the configuration file if it exists
    source_config_file() {
        local config_file="$HOME/.config/tdorc"
        if [ -f "$config_file" ]; then
            source "$config_file"
        fi
    }

    # If none of the variables are set as environment variables, source the config file
    if [ "$env_variables_set" = false ]; then
        source_config_file
    fi
}

# validate whether a variable is set to true or false, and set to default otherwise
validate_and_set() {
    local default_val="${2:-true}"
    local var_value="${1:-$default_val}"
    if [[ "$var_value" != "true" && "$var_value" != "false" ]]; then
        var_value=$default_val
    fi
    echo "$var_value"
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
        $EDITOR "$file_path"
        commit_changes "$(dirname "$file_path")"
    else
        echo "$file_path" && exit 0
    fi
}

find_note() {
    root="$NOTES_DIR"

    if $INTERACTIVE; then
        cd "$root" || return
        rg -li --sort path "$1" |
            fzf --bind "enter:execute($EDITOR {})" \
                --preview "bat --style=numbers --color=always --line-range=:500 {} || cat {}"
        commit_changes
    else
        rg -li --sort path "$1" "$root"
    fi
}

pending_todos() {
    local todo_cmd=''
    if [ "$EDITOR" = "vim" ] || [ "$EDITOR" = "nvim" ]; then
        todo_cmd='+"/[\ \]" +"norm! n"'
    fi
    local editor="$EDITOR $todo_cmd"

    root="${TODOS_DIR:-$NOTES_DIR}"

    if $INTERACTIVE; then
        cd "$root" || return
        rg -l --glob '!/templates/*' '\[ \]' |
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
    [ ! -f "$note_file" ] && new_file="true" || new_file="false"
    create_file "$note_file" "$template"
    if [ "$new_file" = "true" ]; then
      [ "$(validate_and_set "${FILE_NAME_AS_TITLE}" false)" = "true" ] && echo -e "# $1" >>"$note_file"
      [ "$(validate_and_set "${TIMESTAMP_NEWNOTE}" false)" = "true" ] && add_timestamp "$note_file" "${NOTE_TIMESTAMP:-"## %a. %b %d, %Y - %I:%M%p"}"
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
    [ "$(validate_and_set "${TIMESTAMP_ENTRY}")" = "true" ] && add_timestamp "$entry_file" "${ENTRY_TIMESTAMP:-}"
    write_file "$entry_file" "$root"
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
    *) new_note "$1" ;;
    esac
}

main "$@"
