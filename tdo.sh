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
tdo next_monday
# open last monday's todo (previous week)
tdo prev_monday
# open todo from 2 weeks ago
tdo 2_weeks_ago
# open last year's todo
tdo last_year
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
tdo e prev_tuesday
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

days_until_weekday() {
    local target_day="$1"
    local date_cmd=$(get_date_command)
    local current_day=$($date_cmd +%w)
    local days_ahead=$(((target_day - current_day + 7) % 7))
    # If target is today, go to next week
    [ $days_ahead -eq 0 ] && days_ahead=7
    echo $days_ahead
}

days_since_weekday() {
    local target_day="$1"
    local date_cmd=$(get_date_command)
    local current_day=$($date_cmd +%w)
    local days_back=$(((current_day - target_day + 7) % 7))
    # If target is today, go to last week
    [ $days_back -eq 0 ] && days_back=7
    echo "-$days_back"
}

days_to_weekday_same_week() {
    local target_day="$1"
    local date_cmd=$(get_date_command)
    local current_day=$($date_cmd +%w)

    # Convert Sunday=0 to Monday=0 week format
    # Sunday becomes 6, Monday becomes 0, Tuesday becomes 1, etc.
    local current_day_mon_week=$(((current_day + 6) % 7))
    local target_day_mon_week=$(((target_day + 6) % 7))

    local days_diff=$((target_day_mon_week - current_day_mon_week))
    echo "$days_diff"
}

parse_natural_date() {
    local input="$1"
    local lower_input=$(echo "$input" | tr '[:upper:]' '[:lower:]')

    case "$lower_input" in
    "today") echo "0" ;;
    "tomorrow") echo "1" ;;
    "yesterday") echo "-1" ;;

    "sunday" | "sun") echo $(days_to_weekday_same_week 0) ;;
    "monday" | "mon") echo $(days_to_weekday_same_week 1) ;;
    "tuesday" | "tue") echo $(days_to_weekday_same_week 2) ;;
    "wednesday" | "wed") echo $(days_to_weekday_same_week 3) ;;
    "thursday" | "thu") echo $(days_to_weekday_same_week 4) ;;
    "friday" | "fri") echo $(days_to_weekday_same_week 5) ;;
    "saturday" | "sat") echo $(days_to_weekday_same_week 6) ;;

    "next_sunday" | "next_sun") echo $(days_until_weekday 0) ;;
    "next_monday" | "next_mon") echo $(days_until_weekday 1) ;;
    "next_tuesday" | "next_tue") echo $(days_until_weekday 2) ;;
    "next_wednesday" | "next_wed") echo $(days_until_weekday 3) ;;
    "next_thursday" | "next_thu") echo $(days_until_weekday 4) ;;
    "next_friday" | "next_fri") echo $(days_until_weekday 5) ;;
    "next_saturday" | "next_sat") echo $(days_until_weekday 6) ;;

    "last_sunday" | "last_sun") echo $(days_since_weekday 0) ;;
    "last_monday" | "last_mon") echo $(days_since_weekday 1) ;;
    "last_tuesday" | "last_tue") echo $(days_since_weekday 2) ;;
    "last_wednesday" | "last_wed") echo $(days_since_weekday 3) ;;
    "last_thursday" | "last_thu") echo $(days_since_weekday 4) ;;
    "last_friday" | "last_fri") echo $(days_since_weekday 5) ;;
    "last_saturday" | "last_sat") echo $(days_since_weekday 6) ;;

    "next_week") echo "7" ;;
    "last_week") echo "-7" ;;
    "next_month") echo "30" ;;
    "last_month") echo "-30" ;;
    "last_year") echo "-365" ;;
    "next_year") echo "365" ;;

    # Programmatic patterns (handle both singular and plural)
    [0-9]*_week_from_now | [0-9]*_weeks_from_now)
        local weeks="${lower_input%_week*_from_now}"
        if [[ "$weeks" =~ ^[0-9]+$ ]]; then
            echo $((weeks * 7))
        else
            echo "$input"
        fi
        ;;
    [0-9]*_week_ago | [0-9]*_weeks_ago)
        local weeks="${lower_input%_week*_ago}"
        if [[ "$weeks" =~ ^[0-9]+$ ]]; then
            echo $((weeks * -7))
        else
            echo "$input"
        fi
        ;;
    [0-9]*_month_from_now | [0-9]*_months_from_now)
        local months="${lower_input%_month*_from_now}"
        if [[ "$months" =~ ^[0-9]+$ ]]; then
            local date_cmd=$(get_date_command)
            local target_date=$($date_cmd -d "+$months months" +'%Y-%m-%d')
            local current_date=$($date_cmd +'%Y-%m-%d')
            local days_diff=$((($($date_cmd -d "$target_date" +%s) - $($date_cmd -d "$current_date" +%s)) / 86400))
            echo "$days_diff"
        else
            echo "$input"
        fi
        ;;
    [0-9]*_month_ago | [0-9]*_months_ago)
        local months="${lower_input%_month*_ago}"
        if [[ "$months" =~ ^[0-9]+$ ]]; then
            local date_cmd=$(get_date_command)
            local target_date=$($date_cmd -d "-$months months" +'%Y-%m-%d')
            local current_date=$($date_cmd +'%Y-%m-%d')
            local days_diff=$((($($date_cmd -d "$target_date" +%s) - $($date_cmd -d "$current_date" +%s)) / 86400))
            echo "$days_diff"
        else
            echo "$input"
        fi
        ;;
    [0-9]*_year_from_now | [0-9]*_years_from_now)
        local years="${lower_input%_year*_from_now}"
        if [[ "$years" =~ ^[0-9]+$ ]]; then
            local date_cmd=$(get_date_command)
            local target_date=$($date_cmd -d "+$years years" +'%Y-%m-%d')
            local current_date=$($date_cmd +'%Y-%m-%d')
            local days_diff=$((($($date_cmd -d "$target_date" +%s) - $($date_cmd -d "$current_date" +%s)) / 86400))
            echo "$days_diff"
        else
            echo "$input"
        fi
        ;;
    [0-9]*_year_ago | [0-9]*_years_ago)
        local years="${lower_input%_year*_ago}"
        if [[ "$years" =~ ^[0-9]+$ ]]; then
            local date_cmd=$(get_date_command)
            local target_date=$($date_cmd -d "-$years years" +'%Y-%m-%d')
            local current_date=$($date_cmd +'%Y-%m-%d')
            local days_diff=$((($($date_cmd -d "$target_date" +%s) - $($date_cmd -d "$current_date" +%s)) / 86400))
            echo "$days_diff"
        else
            echo "$input"
        fi
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
    "" | [0-9-]* | *day* | *week* | *month* | *year* | *sun | *mon | *tue | *wed | *thu | *fri | *sat | next_* | last_* | tomorrow) new_todo "$1" ;;
    *) find_or_create_note "$1" ;;
    esac
}

main "$@"
