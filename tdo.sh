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
-c  | --commit  | c  | commit     commits changes in the argument directory
-e  | --entry   | e  | entry      creates/opens journal entry (accepts offset, title, or -m)
      e f       | ef              searches journal entries for argument term
      e list    | el              lists/browses journal entries in reverse chronological order
      e -m      | em              quickly logs a message to today's (or offset) journal entry
-m  | --message | m               quickly adds a todo item to today's (or offset) todo file
-f  | --find    | f  | find       searches for argument term in notes
-n  | --note    | n  | note       creates a new draft note with timestamp title
-t  | --todo    | t  | todo       shows all pending todos (supports -m to add todo)
-p  | --pending | p  | pending    shows the count of pending todos
-h  | --help    | h  | help       shows this help message

Example:
# todos: supports date formats like numbers, tomorrow, next-week, 3-months-ago, etc.
tdo | tdo tomorrow | tdo monday | tdo next-mon | tdo 2-weeks-ago | tdo 2025-07-14
# quick add todo item:
tdo -m "Buy milk" | tdo tomorrow -m "Review pull request"
# journal entries: supports same date formats as todos, plus optional titles
tdo e 1 | tdo e tuesday | tdo e last-tuesday | tdo e 1-month-later
tdo e retro | tdo e tomorrow retro
# quick journal logging:
tdo e -m "Had productive standup" | tdo em "Wrapped up project release"
# search or browse journal entries:
tdo e f standup | tdo ef release | tdo e list | tdo el
# Open or create vim.md in notes/tech/ directory
tdo tech/vim
# search notes with neovim in them
tdo f neovim

For more information, visit https://github.com/2kabhishek/tdo
EOF
}

config_setup() {
    local config_file="$HOME/.config/tdorc"
    # shellcheck source=/dev/null
    [ -f "$config_file" ] && source "$config_file"
    add_entry_timestamp="${ADD_ENTRY_TIMESTAMP:-true}"
    add_new_note_timestamp="${ADD_NEW_NOTE_TIMESTAMP:-false}"
    filename_as_title="${FILE_NAME_AS_TITLE:-false}"
    entry_timestamp_format="${ENTRY_TIMESTAMP_FORMAT:-"## %a, %I:%M %p"}"
    note_timestamp_format="${NOTE_TIMESTAMP_FORMAT:-"## %a. %b %d, %Y - %I:%M %p"}"
}

get_journal_root() {
    local dir="${JOURNAL_DIR:-$NOTES_DIR}"
    dir="${dir%/}"
    if [[ "$dir" =~ /entries$ ]]; then
        echo "${dir%/entries}"
    else
        echo "$dir"
    fi
}

get_entries_dir() {
    local root="${JOURNAL_DIR:-$NOTES_DIR}"
    root="${root%/}"
    if [[ "$root" =~ /entries$ ]]; then
        echo "$root"
    else
        echo "$root/entries"
    fi
}

get_todos_root() {
    local dir="${TODOS_DIR:-$NOTES_DIR}"
    dir="${dir%/}"
    if [[ "$dir" =~ /todos$ ]]; then
        echo "${dir%/todos}"
    else
        echo "$dir"
    fi
}

get_todos_dir() {
    local root="${TODOS_DIR:-$NOTES_DIR}"
    root="${root%/}"
    if [[ "$root" =~ /todos$ ]]; then
        echo "$root"
    else
        echo "$root/todos"
    fi
}

get_template() {
    local type="$1"
    local custom_root="${2:-}"
    if [ -n "$custom_root" ] && [ -f "$custom_root/templates/$type.md" ]; then
        echo "$custom_root/templates/$type.md"
    elif [ -n "$NOTES_DIR" ] && [ -f "$NOTES_DIR/templates/$type.md" ]; then
        echo "$NOTES_DIR/templates/$type.md"
    fi
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
    local date_cmd
    date_cmd=$(get_date_command)
    local current_day
    current_day=$($date_cmd +%w)

    echo $((target_day - current_day))
}

calculate_date_offset() {
    local value="$1"
    local unit="$2" # "months" or "years"
    local sign="$3" # "+" or "-"

    local date_cmd
    date_cmd=$(get_date_command)
    local target_date
    target_date=$($date_cmd -d "${sign}${value} ${unit}" +'%Y-%m-%d')
    local current_date
    current_date=$($date_cmd +'%Y-%m-%d')
    echo $((($($date_cmd -d "$target_date" +%s) - $($date_cmd -d "$current_date" +%s)) / 86400))
}

parse_natural_date() {
    local input="$1"
    local lower_input
    lower_input=$(echo "$input" | tr '[:upper:]' '[:lower:]')

    case "$lower_input" in
    "today") echo "0" ;;
    "tomorrow") echo "1" ;;
    "yesterday") echo "-1" ;;

    "sunday" | "sun") days_to_weekday 0 ;;
    "monday" | "mon") days_to_weekday 1 ;;
    "tuesday" | "tue") days_to_weekday 2 ;;
    "wednesday" | "wed") days_to_weekday 3 ;;
    "thursday" | "thu") days_to_weekday 4 ;;
    "friday" | "fri") days_to_weekday 5 ;;
    "saturday" | "sat") days_to_weekday 6 ;;

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
    [0-9]*-week-later | [0-9]*-weeks-later)
        local weeks="${lower_input%-week*-later}"
        [[ "$weeks" =~ ^[0-9]+$ ]] && echo $((weeks * 7))
        ;;
    [0-9]*-week-ago | [0-9]*-weeks-ago)
        local weeks="${lower_input%-week*-ago}"
        [[ "$weeks" =~ ^[0-9]+$ ]] && echo $((weeks * -7))
        ;;
    [0-9]*-month-later | [0-9]*-months-later)
        local months="${lower_input%-month*-later}"
        [[ "$months" =~ ^[0-9]+$ ]] && calculate_date_offset "$months" "months" "+"
        ;;
    [0-9]*-month-ago | [0-9]*-months-ago)
        local months="${lower_input%-month*-ago}"
        [[ "$months" =~ ^[0-9]+$ ]] && calculate_date_offset "$months" "months" "-"
        ;;
    [0-9]*-year-later | [0-9]*-years-later)
        local years="${lower_input%-year*-later}"
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

generate_entry_file_path() {
    local date_input="${1:-0}"
    local title="${2:-}"
    local base_path

    if ! base_path=$(generate_file_path "$date_input"); then
        return 1
    fi

    if [ -n "$title" ]; then
        title="${title%.md}"
        title=$(echo "$title" | tr ' ' '-')
        echo "${base_path%.md}-${title}.md"
    else
        echo "$base_path"
    fi
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
    local file_path="$1"
    local time_format="${2:-## %a, %I:%M %p}"
    local timestamp
    timestamp=$(date +"$time_format")

    if [ -f "$file_path" ]; then
        local last_line
        last_line=$(grep -v '^[[:space:]]*$' "$file_path" 2>/dev/null | tail -n 1)
        if [ "$last_line" = "$timestamp" ]; then
            return 0
        fi
    fi
    echo -e "\n$timestamp\n" >>"$file_path"
}

write_file() {
    local file_path="$1"
    local root="$2"
    local cursor_cmd="${3:-}"

    if $INTERACTIVE; then
        cd "$root" || return
        # shellcheck disable=SC2153
        if [ -n "$cursor_cmd" ] && [[ "$EDITOR" == "vim" || "$EDITOR" == "nvim" ]]; then
            $EDITOR "$cursor_cmd" "$file_path"
        else
            "$EDITOR" "$file_path"
        fi
        commit_changes "$(dirname "$file_path")"
    else
        echo "$file_path" && exit 0
    fi
}

find_note() {
    local root="$NOTES_DIR"
    local term="$1"

    local todo_cmd=''
    if [[ "$EDITOR" == "vim" || "$EDITOR" == "nvim" ]] && [ -n "$term" ]; then
        todo_cmd="+'/$term' +'norm! n'"
    fi
    local editor="$EDITOR $todo_cmd"

    local search_dirs=("$root")
    if [ -n "$JOURNAL_DIR" ] && [ "$JOURNAL_DIR" != "$NOTES_DIR" ] && [ -d "$JOURNAL_DIR" ]; then
        search_dirs+=("$JOURNAL_DIR")
    fi
    if [ -n "$TODOS_DIR" ] && [ "$TODOS_DIR" != "$NOTES_DIR" ] && [ -d "$TODOS_DIR" ]; then
        search_dirs+=("$TODOS_DIR")
    fi

    if $INTERACTIVE; then
        cd "$root" || return
        rg -li --sort path "$term" "${search_dirs[@]}" | sort |
            fzf --bind "enter:execute($editor {})" \
                --preview "bat --style=numbers --color=always --line-range=:500 {} || cat {}"
        commit_changes "$root"
    else
        rg -li --sort path "$term" "${search_dirs[@]}" || true
    fi
}

count_pending_todos() {
    local root="${TODOS_DIR:-$NOTES_DIR}"
    local count
    count=$(rg --count-matches --no-filename --glob '!**/templates/*' --glob '!**/entries/*' '\[ \]' "$root" | awk '{s+=$1} END {print +s}')
    echo "${count}"
}

pending_todos() {
    local todo_cmd=''
    if [ "$EDITOR" = "vim" ] || [ "$EDITOR" = "nvim" ]; then
        todo_cmd="+'/ ]' +'norm! n'"
    fi
    local editor="$EDITOR $todo_cmd"

    local root="${TODOS_DIR:-$NOTES_DIR}"

    if $INTERACTIVE; then
        cd "$root" || return
        rg -l --glob '!**/templates/*' --glob '!**/entries/*' '\[ \]' "$root" | sort |
            fzf --bind "enter:execute($editor {})" --preview 'rg -e "\[ \]" {}'
        commit_changes "$root"
    else
        rg -l --glob '!**/templates/*' --glob '!**/entries/*' '\[ \]' "$root" | sort
    fi
}

new_note() {
    local root="$NOTES_DIR"
    local note_file="$root/notes/$1.md"
    local template
    template=$(get_template "note" "$root")
    if [ ! -f "$note_file" ]; then
        create_file "$note_file" "$template"
        $filename_as_title && echo -e "# $1" >>"$note_file"
        $add_new_note_timestamp && add_timestamp "$note_file" "$note_timestamp_format"
    fi
    write_file "$note_file" "$root"
}

draft_note() {
    local title
    title='drafts/'$(date +'%m-%d-%H-%M-%S')
    new_note "$title"
}

quick_entry() {
    local message="$1"
    local date_input="${2:-0}"
    local title="${3:-}"
    local entries_dir
    local journal_root
    local file_path

    if [ -z "$message" ]; then
        echo "Error: Message cannot be empty for quick entry (-m)." >&2
        return 1
    fi

    entries_dir=$(get_entries_dir)
    journal_root=$(get_journal_root)

    if ! generate_file_path "$date_input" >/dev/null 2>&1; then
        title="$date_input"
        date_input="0"
    fi

    if [ -n "$title" ]; then
        file_path=$(generate_entry_file_path "$date_input" "$title")
    else
        file_path=$(generate_file_path "$date_input")
    fi

    local entry_file="$entries_dir/$file_path"
    local template
    template=$(get_template "entry" "$journal_root")

    create_file "$entry_file" "$template"
    $add_entry_timestamp && add_timestamp "$entry_file" "$entry_timestamp_format"

    local formatted_message="$message"
    if [[ ! "$formatted_message" =~ ^[-*#] ]]; then
        formatted_message="- $formatted_message"
    fi

    echo "$formatted_message" >>"$entry_file"
    commit_changes "$(dirname "$entry_file")"

    if $INTERACTIVE; then
        echo "Logged entry: $message"
    else
        echo "$entry_file"
        [[ "${BATS_TESTING:-}" != "true" ]] && exit 0
        return 0
    fi
}

quick_todo() {
    local message="$1"
    local date_input="${2:-0}"
    local todos_dir
    local todos_root
    local file_path

    if [ -z "$message" ]; then
        echo "Error: Message cannot be empty for quick todo (-m)." >&2
        return 1
    fi

    todos_dir=$(get_todos_dir)
    todos_root=$(get_todos_root)

    if ! file_path=$(generate_file_path "$date_input"); then
        file_path=$(generate_file_path "0")
    fi

    local todo_file="$todos_dir/$file_path"
    local template
    template=$(get_template "todo" "$todos_root")

    create_file "$todo_file" "$template"

    local formatted_message="$message"
    if [[ ! "$formatted_message" =~ ^[-*] ]] && [[ ! "$formatted_message" =~ ^\[[[:space:]xX]?\] ]]; then
        formatted_message="- [ ] $formatted_message"
    elif [[ ! "$formatted_message" =~ ^[-*] ]]; then
        formatted_message="- $formatted_message"
    fi

    echo "$formatted_message" >>"$todo_file"
    commit_changes "$(dirname "$todo_file")"

    if $INTERACTIVE; then
        echo "Added todo: $message"
    else
        echo "$todo_file"
        [[ "${BATS_TESTING:-}" != "true" ]] && exit 0
        return 0
    fi
}

list_entries() {
    local entries_dir
    local journal_root
    entries_dir=$(get_entries_dir)
    journal_root=$(get_journal_root)

    if [ ! -d "$entries_dir" ]; then
        return 0
    fi

    local editor="$EDITOR"

    if $INTERACTIVE; then
        cd "$journal_root" || return
        find "$entries_dir" -type f -name '*.md' -not -path '*/.*' | sort -r |
            fzf --delimiter / --with-nth -1 \
                --bind "enter:execute($editor {})" \
                --header "Journal Entries (Enter to open)" \
                --preview "bat --style=numbers --color=always --line-range=:500 {} || cat {}"
        commit_changes "$entries_dir"
    else
        find "$entries_dir" -type f -name '*.md' -not -path '*/.*' | sed 's|.*/||' | sort -r
    fi
}

find_entry() {
    local term="$1"
    local entries_dir
    local journal_root
    entries_dir=$(get_entries_dir)
    journal_root=$(get_journal_root)

    if [ ! -d "$entries_dir" ]; then
        return 0
    fi

    if [ -z "$term" ]; then
        list_entries
        return 0
    fi

    local todo_cmd=''
    if [[ "$EDITOR" == "vim" || "$EDITOR" == "nvim" ]] && [ -n "$term" ]; then
        todo_cmd="+'/$term' +'norm! n'"
    fi
    local editor="$EDITOR $todo_cmd"

    if $INTERACTIVE; then
        cd "$journal_root" || return
        (rg -li --sort path "$term" "$entries_dir" || true) | sort -r |
            fzf --delimiter / --with-nth -1 \
                --bind "enter:execute($editor {})" \
                --header "Journal Search: '$term'" \
                --preview "bat --style=numbers --color=always --line-range=:500 {} || cat {}"
        commit_changes "$entries_dir"
    else
        (rg -li --sort path "$term" "$entries_dir" || true) | sed 's|.*/||' | sort -r
    fi
}

find_or_create_entry() {
    local title="$1"
    local entries_dir
    local journal_root
    local template
    entries_dir=$(get_entries_dir)
    journal_root=$(get_journal_root)
    template=$(get_template "entry" "$journal_root")

    if [ -f "$entries_dir/$title" ]; then
        write_file "$entries_dir/$title" "$journal_root" "+$"
        return
    fi

    local matching_entries=""
    if [ -d "$entries_dir" ]; then
        matching_entries=$(find "$entries_dir" -type f -not -path '*/\.*' -iname "*$title*")
    fi

    local today_path
    today_path=$(generate_entry_file_path "0" "$title")
    local new_entry_file="$entries_dir/$today_path"

    if [ -z "$matching_entries" ]; then
        create_file "$new_entry_file" "$template"
        $add_entry_timestamp && add_timestamp "$new_entry_file" "$entry_timestamp_format"
        write_file "$new_entry_file" "$journal_root" "+$"
    else
        if $INTERACTIVE; then
            cd "$journal_root" || return
            local match_count
            match_count=$(echo "$matching_entries" | wc -l)
            if [ "$match_count" -eq 1 ]; then
                $EDITOR "+$" "$matching_entries"
            else
                local new_dir
                new_dir=$(dirname "$new_entry_file")
                find "$entries_dir" -type f -not -path '*/\.*' -iname "*$title*" | sort -r |
                    fzf --delimiter / --with-nth -1 \
                        --bind "enter:execute($EDITOR +$ {})" \
                        --bind "ctrl-n:execute(mkdir -p '$new_dir' && [ -f '$template' ] && cp '$template' '$new_entry_file'; $EDITOR +$ '$new_entry_file')" \
                        --header "Ctrl-n: Create today's entry '$title'" \
                        --preview "bat --style=numbers --color=always --line-range=:500 {} || cat {}"
            fi
            commit_changes "$entries_dir"
        else
            echo "$matching_entries" | sed 's|.*/||' | sort -r
        fi
    fi
}

new_todo() {
    local has_msg=false
    local msg=""
    local remaining=()
    while [ $# -gt 0 ]; do
        if [ "$1" = "-m" ]; then
            has_msg=true
            msg="$2"
            shift 2
        else
            remaining+=("$1")
            shift
        fi
    done

    if $has_msg; then
        quick_todo "$msg" "${remaining[0]:-0}"
        return
    fi

    local todos_dir
    local todos_root
    local file_path
    todos_dir=$(get_todos_dir)
    todos_root=$(get_todos_root)

    local arg1="${remaining[0]:-}"

    if ! file_path=$(generate_file_path "$arg1"); then
        find_or_create_note "$arg1"
        return
    fi

    local todo_file="$todos_dir/$file_path"
    local template
    template=$(get_template "todo" "$todos_root")
    create_file "$todo_file" "$template"
    write_file "$todo_file" "$todos_root"
}

new_entry() {
    local has_msg=false
    local msg=""
    local remaining=()
    while [ $# -gt 0 ]; do
        if [ "$1" = "-m" ]; then
            has_msg=true
            msg="$2"
            shift 2
        else
            remaining+=("$1")
            shift
        fi
    done

    if $has_msg; then
        quick_entry "$msg" "${remaining[0]:-0}" "${remaining[1]:-}"
        return
    fi

    case "${remaining[0]:-}" in
    -f | --find | f | find)
        find_entry "${remaining[@]:1}"
        return
        ;;
    -l | --list | l | list | ls)
        list_entries
        return
        ;;
    esac

    local entries_dir
    local journal_root
    local file_path
    entries_dir=$(get_entries_dir)
    journal_root=$(get_journal_root)

    local arg1="${remaining[0]:-}"
    local arg2="${remaining[1]:-}"

    if file_path=$(generate_file_path "$arg1"); then
        if [ -n "$arg2" ]; then
            file_path=$(generate_entry_file_path "$arg1" "$arg2")
        fi
        local entry_file="$entries_dir/$file_path"
        local template
        template=$(get_template "entry" "$journal_root")
        create_file "$entry_file" "$template"
        $add_entry_timestamp && add_timestamp "$entry_file" "$entry_timestamp_format"
        write_file "$entry_file" "$journal_root" "+$"
        return
    fi

    find_or_create_entry "$arg1"
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
            commit_changes "$root"
        else
            echo "$notes"
        fi
    fi
}

main() {
    check_command "rg"
    check_command "fzf"
    config_setup
    check_env "NOTES_DIR"

    case "$1" in
    -c | --commit | c | commit) commit_changes "$(dirname "$2")" ;;
    -e | --entry | e | entry)
        shift
        new_entry "$@"
        ;;
    ef)
        shift
        find_entry "$@"
        ;;
    el)
        shift
        list_entries "$@"
        ;;
    em)
        shift
        quick_entry "$@"
        ;;
    -m | --message)
        shift
        quick_todo "$@"
        ;;
    -f | --find | f | find)
        shift
        find_note "$@"
        ;;
    -h | --help | h | help) display_help ;;
    -n | --note | n | note) draft_note ;;
    -t | --todo | t | todo)
        shift
        if [ "$1" = "-m" ]; then
            quick_todo "$2" "$3"
        else
            pending_todos
        fi
        ;;
    -p | --pending | p | pending) count_pending_todos ;;
    "" | [0-9-]* | *day* | *week* | *month* | *year* | *sun | *mon | *tue | *wed | *thu | *fri | *sat | next-* | last-* | tomorrow)
        new_todo "$@"
        ;;
    *)
        local has_m=false
        for a in "$@"; do
            [ "$a" = "-m" ] && has_m=true
        done
        if $has_m; then
            new_todo "$@"
        else
            find_or_create_note "$1"
        fi
        ;;
    esac
}

# Only run main if not in testing mode
if [[ "${BATS_TESTING:-}" != "true" ]]; then
    main "$@"
fi
