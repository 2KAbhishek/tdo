#!/usr/bin/env bash

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
-p | --pending| p | pending shows the count of pending todos
-h | --help   | h | help    shows this help message

Example:
# open today's todo
tdo
# open tomorrow's todo
tdo 1
tdo tomorrow
# open monday's todo from this week
tdo monday
# open next monday's todo (next week)
tdo next-monday
# open last monday's todo (previous week)
tdo last-monday
# open todo from 2 weeks ago
tdo 2-weeks-ago
# open last year's todo
tdo last-year
# open or create the note tech/vim.md
tdo tech/vim
# creates a new draft note
tdo n
# open today's journal entry
tdo e
# open day before yesterday's journal entry
tdo e -2
# open tuesday's journal entry from this week
tdo e tuesday
# open previous tuesday's journal entry
tdo e last-tuesday
# search for neovim in all notes
tdo f neovim
# review all notes
tdo f
# show all pending todos
tdo t
# show count of pending todos
tdo p

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

get_date_command() {
    if [ "$(uname)" = "Darwin" ]; then
        check_command "gdate"
        echo "gdate"
    else
        echo "date"
    fi
}

days_to_weekday() {
    local target_day="$1"
    local date_cmd=$(get_date_command)
    local current_day=$($date_cmd +%w)

    echo $((target_day - current_day))
}

calculate_date_offset() {
    local value="$1"
    local unit="$2" # "months" or "years"
    local sign="$3" # "+" or "-"

    local date_cmd=$(get_date_command)
    local target_date=$($date_cmd -d "${sign}${value} ${unit}" +'%Y-%m-%d')
    local current_date=$($date_cmd +'%Y-%m-%d')
    echo $((($($date_cmd -d "$target_date" +%s) - $($date_cmd -d "$current_date" +%s)) / 86400))
}

parse_natural_date() {
    local input="$1"
    local lower_input=$(echo "$input" | tr '[:upper:]' '[:lower:]')

    case "$lower_input" in
    "today") echo "0" ;;
    "tomorrow") echo "1" ;;
    "yesterday") echo "-1" ;;

    "sunday" | "sun") echo $(days_to_weekday 0) ;;
    "monday" | "mon") echo $(days_to_weekday 1) ;;
    "tuesday" | "tue") echo $(days_to_weekday 2) ;;
    "wednesday" | "wed") echo $(days_to_weekday 3) ;;
    "thursday" | "thu") echo $(days_to_weekday 4) ;;
    "friday" | "fri") echo $(days_to_weekday 5) ;;
    "saturday" | "sat") echo $(days_to_weekday 6) ;;

    "next-sunday" | "next-sun") echo $(($(days_to_weekday 0) + 7)) ;;
    "next-monday" | "next-mon") echo $(($(days_to_weekday 1) + 7)) ;;
    "next-tuesday" | "next-tue") echo $(($(days_to_weekday 2) + 7)) ;;
    "next-wednesday" | "next-wed") echo $(($(days_to_weekday 3) + 7)) ;;
    "next-thursday" | "next-thu") echo $(($(days_to_weekday 4) + 7)) ;;
    "next-friday" | "next-fri") echo $(($(days_to_weekday 5) + 7)) ;;
    "next-saturday" | "next-sat") echo $(($(days_to_weekday 6) + 7)) ;;

    "last-sunday" | "last-sun") echo $(($(days_to_weekday 0) - 7)) ;;
    "last-monday" | "last-mon") echo $(($(days_to_weekday 1) - 7)) ;;
    "last-tuesday" | "last-tue") echo $(($(days_to_weekday 2) - 7)) ;;
    "last-wednesday" | "last-wed") echo $(($(days_to_weekday 3) - 7)) ;;
    "last-thursday" | "last-thu") echo $(($(days_to_weekday 4) - 7)) ;;
    "last-friday" | "last-fri") echo $(($(days_to_weekday 5) - 7)) ;;
    "last-saturday" | "last-sat") echo $(($(days_to_weekday 6) - 7)) ;;

    "next-week") echo "7" ;;
    "last-week") echo "-7" ;;
    "next-month") echo "30" ;;
    "last-month") echo "-30" ;;
    "last-year") echo "-365" ;;
    "next-year") echo "365" ;;

    # Programmatic patterns (handle both singular and plural)
    [0-9]*-week-from-now | [0-9]*-weeks-from-now)
        local weeks="${lower_input%-week*-from-now}"
        [[ "$weeks" =~ ^[0-9]+$ ]] && echo $((weeks * 7))
        ;;
    [0-9]*-week-ago | [0-9]*-weeks-ago)
        local weeks="${lower_input%-week*-ago}"
        [[ "$weeks" =~ ^[0-9]+$ ]] && echo $((weeks * -7))
        ;;
    [0-9]*-month-from-now | [0-9]*-months-from-now)
        local months="${lower_input%-month*-from-now}"
        [[ "$months" =~ ^[0-9]+$ ]] && calculate_date_offset "$months" "months" "+"
        ;;
    [0-9]*-month-ago | [0-9]*-months-ago)
        local months="${lower_input%-month*-ago}"
        [[ "$months" =~ ^[0-9]+$ ]] && calculate_date_offset "$months" "months" "-"
        ;;
    [0-9]*-year-from-now | [0-9]*-years-from-now)
        local years="${lower_input%-year*-from-now}"
        [[ "$years" =~ ^[0-9]+$ ]] && calculate_date_offset "$years" "years" "+"
        ;;
    [0-9]*-year-ago | [0-9]*-years-ago)
        local years="${lower_input%-year*-ago}"
        [[ "$years" =~ ^[0-9]+$ ]] && calculate_date_offset "$years" "years" "-"
        ;;

    *) echo "$input" ;;
    esac
}

generate_file_path() {
    local input="${1:-0}"
    local offset

    offset=$(parse_natural_date "$input")

    if [ "$offset" = "$input" ]; then
        if [[ "$input" =~ ^[0-9-]+$ ]]; then
            offset="$input"
        else
            return 1
        fi
    fi

    date_cmd=$(get_date_command)
    if [[ "$offset" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        year=$($date_cmd -d "$offset" +'%Y')
        month=$($date_cmd -d "$offset" +'%m')
        day=$($date_cmd -d "$offset" +'%d')
    else
        year=$($date_cmd -d "$offset days" +'%Y')
        month=$($date_cmd -d "$offset days" +'%m')
        day=$($date_cmd -d "$offset days" +'%d')
    fi
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
    if [ "$EDITOR" = "vim" ] || [ "$EDITOR" = "nvim" ] && [ -n "$1" ]; then
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

count_pending_todos() {
    root="${TODOS_DIR:-$NOTES_DIR}"
    count=$(rg --count-matches --no-filename --glob '!/templates/*' '\[ \]' "$root" | awk '{s+=$1} END {print +s}')
    echo "${count}"
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

    if ! file_path=$(generate_file_path "$1"); then
        find_or_create_note "$1"
        return
    fi

    todo_file="$root/todos/$file_path"
    template="$root/templates/todo.md"
    create_file "$todo_file" "$template"
    write_file "$todo_file" "$root"
}

new_entry() {
    root="${JOURNAL_DIR:-$NOTES_DIR}"

    if ! file_path=$(generate_file_path "$1"); then
        find_or_create_note "$1"
        return
    fi

    entry_file="$root/entries/$file_path"
    template="$root/templates/entry.md"
    create_file "$entry_file" "$template"
    $add_entry_timestamp && add_timestamp "$entry_file" "$entry_timestamp_format"
    write_file "$entry_file" "$root"
}

find_or_create_note() {
    root="$NOTES_DIR"

    if [ -f "$root/$1" ]; then
        write_file "$root/$1" "$root"
        return
    fi

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
    -p | --pending | p | pending) count_pending_todos ;;
    "" | [0-9-]* | *day* | *week* | *month* | *year* | *sun | *mon | *tue | *wed | *thu | *fri | *sat | next-* | last-* | tomorrow) new_todo "$1" ;;
    *) find_or_create_note "$1" ;;
    esac
}

main "$@"
