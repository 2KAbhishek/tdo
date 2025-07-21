#!/usr/bin/env bash

setup() {
    export TEST_DIR="/tmp/tdo_test_$$"
    export NOTES_DIR="$TEST_DIR/notes"
    export TODOS_DIR="$TEST_DIR/notes"
    export JOURNAL_DIR="$TEST_DIR/notes"
    export EDITOR="echo"

    mkdir -p "$NOTES_DIR"/{notes,todos,entries,templates}
    echo "# Todo Template" >"$NOTES_DIR/templates/todo.md"
    echo "# Note Template" >"$NOTES_DIR/templates/note.md"
    echo "# Entry Template" >"$NOTES_DIR/templates/entry.md"

    export MOCK_DATE="2025-07-18"
    export MOCK_WEEKDAY="5"
    export MOCK_YEAR="2025"
    export MOCK_MONTH="07"
    export MOCK_DAY="18"
    export MOCK_EPOCH="1721260800"

    export BATS_TESTING=true
    local test_script="$TEST_DIR/tdo_test.sh"
    local script_path

    if [[ "$BATS_TEST_DIRNAME" == */unit ]]; then
        script_path="$BATS_TEST_DIRNAME/../../tdo.sh"
    elif [[ "$BATS_TEST_DIRNAME" == */integration ]]; then
        script_path="$BATS_TEST_DIRNAME/../../tdo.sh"
    else
        script_path="$BATS_TEST_DIRNAME/../tdo.sh"
    fi

    cp "$script_path" "$test_script"
    source "$test_script"
    if command -v bats-assert &>/dev/null; then
        load "$(bats-assert)"
    fi

    setup_mocks
}

setup_mocks() {
    get_date_command() { echo "mock_date"; }
    date() { mock_date "$@"; }
    rg() {
        local search_dir=""
        local last_arg=""
        for arg in "$@"; do
            if [[ -d "$arg" ]]; then
                search_dir="$arg"
            fi
            last_arg="$arg"
        done

        case "$1" in
        -li | --files-with-matches)
            shift
            if [[ "$*" == *"vim"* ]]; then
                if [[ -f "$search_dir/notes/vim.md" ]]; then
                    echo "notes/vim.md"
                elif [[ -f "$search_dir/notes/vim-tips.md" ]]; then
                    echo "notes/vim-tips.md"
                fi
            elif [[ "$*" == *"docker"* ]]; then
                echo "notes/tech/docker.md"
            fi
            ;;
        -l)
            shift
            if [[ "$*" == *"\\[ \\]"* ]]; then
                local todo_files=""
                if [[ -f "$search_dir/todos/2025/07/project.md" ]]; then
                    todo_files="todos/2025/07/project.md"
                fi
                if [[ -f "$search_dir/todos/2025/07/personal.md" ]]; then
                    todo_files="$todo_files
todos/2025/07/personal.md"
                fi
                if [[ -f "$search_dir/todos/2025/07/test.md" ]]; then
                    todo_files="$todo_files
todos/2025/07/test.md"
                fi
                if [[ -f "$search_dir/todos/2025/08/future.md" ]]; then
                    todo_files="$todo_files
todos/2025/08/future.md"
                fi
                echo "$todo_files" | grep -v "^$"
            fi
            ;;
        --count-matches)
            if [[ "$*" == *"\\[ \\]"* ]]; then
                local count=0
                if [[ -f "$search_dir/todos/2025/07/project.md" ]]; then
                    count=$((count + 3))
                fi
                if [[ -f "$search_dir/todos/2025/07/personal.md" ]]; then
                    count=$((count + 2))
                fi
                if [[ -f "$search_dir/todos/2025/08/future.md" ]]; then
                    count=$((count + 2))
                fi
                echo "$count"
            else
                echo "0"
            fi
            ;;
        *)
            echo ""
            ;;
        esac
    }
    fzf() { echo "Mock fzf output"; }

    check_command() {
        if declare -f command >/dev/null 2>&1 && [[ "$(type -t command)" == "function" ]]; then
            if ! command -v "$1" &>/dev/null; then
                echo "Error: The $1 command is not available. Make sure it is installed."
                exit 1
            fi
        else
            return 0
        fi
    }

    # Prevents exit in tests
    write_file() {
        local file_path="$1"
        local root="$2"

        if $INTERACTIVE; then
            cd "$root" || return
            "$EDITOR" "$file_path"
            commit_changes "$(dirname "$file_path")"
        else
            echo "$file_path"
            return 0
        fi
    }

    tdo() { main "$@"; }

    mock_date() {
        case "$1" in
        "+%Y") echo "$MOCK_YEAR" ;;
        "+%m") echo "$MOCK_MONTH" ;;
        "+%d") echo "$MOCK_DAY" ;;
        "+%Y-%m-%d") echo "$MOCK_DATE" ;;
        "+%w") echo "$MOCK_WEEKDAY" ;;
        "+%s") echo "$MOCK_EPOCH" ;;
        "+%d %b %H:%M") echo "18 Jul 14:30" ;;
        "+%m-%d-%H-%M-%S") echo "07-18-14-30-45" ;;
        -d) _handle_date_offset "$2" "$3" ;;
        *) echo "$MOCK_DATE" ;;
        esac
    }
}

_handle_date_offset() {
    local date_spec="$1" format="$2"

    if [[ "$date_spec" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        _format_date "$date_spec" "$format"
    elif [[ "$date_spec" =~ ^-?[0-9]+\ days?$ ]]; then
        local days="${date_spec%% *}"
        local target_date

        case "$days" in
        0) target_date="$MOCK_DATE" ;;
        1) target_date="2025-07-19" ;;
        -1) target_date="2025-07-17" ;;
        -4) target_date="2025-07-14" ;;
        -5) target_date="2025-07-13" ;;
        7) target_date="2025-07-25" ;;
        -7) target_date="2025-07-11" ;;
        14) target_date="2025-08-01" ;;
        -11) target_date="2025-07-07" ;;
        *) target_date=$(_calculate_offset "$days") ;;
        esac

        _format_date "$target_date" "$format"
    else
        _format_date "$MOCK_DATE" "$format"
    fi
}

_format_date() {
    local date_val="$1" format="$2"

    case "$format" in
    "+%Y") echo "${date_val:0:4}" ;;
    "+%m") echo "${date_val:5:2}" ;;
    "+%d") echo "${date_val:8:2}" ;;
    "+%Y-%m-%d") echo "$date_val" ;;
    "+%s") echo "$MOCK_EPOCH" ;;
    *) echo "$date_val" ;;
    esac
}

_calculate_offset() {
    local days="$1"
    local day=$((MOCK_DAY + days))
    local month=$MOCK_MONTH year=$MOCK_YEAR

    if [[ $day -gt 31 ]]; then
        month=08
        day=$((day - 31))
    elif [[ $day -lt 1 ]]; then
        month=06
        day=$((30 + day))
    fi

    printf "%04d-%02d-%02d" $year $month $day
}

teardown() {
    if [[ -n "$TEST_DIR" && "$TEST_DIR" =~ ^/tmp/tdo_test_ ]]; then
        rm -rf "$TEST_DIR"
    fi
}

assert_equal() {
    if [[ "$1" != "$2" ]]; then
        echo "Expected: '$2', Got: '$1'" >&2
        return 1
    fi
}

assert_success() {
    if [[ "$status" -ne 0 ]]; then
        echo "Expected success but got status: $status" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        echo "Expected failure but got success" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

assert_file_exists() {
    if [[ ! -f "$1" ]]; then
        echo "Expected file to exist: $1" >&2
        return 1
    fi
}

assert_dir_exists() {
    if [[ ! -d "$1" ]]; then
        echo "Expected directory to exist: $1" >&2
        return 1
    fi
}

assert_contains() {
    if [[ "$1" != *"$2"* ]]; then
        echo "Expected '$1' to contain '$2'" >&2
        return 1
    fi
}

run_tdo_non_interactive() {
    INTERACTIVE=false tdo "$@"
}

mock_git_not_repo() {
    git() {
        echo "git called with: $*" >&2
        return 1
    }
}

mock_git_repo_with_changes() {
    git() {
        case "$1" in
        "rev-parse") echo ".git" ;;
        "status") echo "?? new_file.txt" ;;
        "pull" | "add" | "commit") return 0 ;;
        *) return 1 ;;
        esac
    }
}

mock_git_repo_no_changes() {
    git() {
        case "$1" in
        "rev-parse") echo ".git" ;;
        "status") echo "" ;;
        *) return 0 ;;
        esac
    }
}

mock_git_repo_failures() {
    git() {
        case "$1" in
        "rev-parse") echo ".git" ;;
        "status") echo "?? file.txt" ;;
        "pull" | "add" | "commit") return 1 ;;
        *) return 1 ;;
        esac
    }
}

test_editor_command_generation() {
    local editor="$1"
    local pattern="$2"
    local expected="$3"

    export EDITOR="$editor"

    local result
    if [[ "$pattern" == *" ]"* ]]; then
        result=$(generate_editor_command_for_todos)
    else
        result=$(generate_editor_command_for_search "$pattern")
    fi

    assert_equal "$result" "$expected"
}

generate_editor_command_for_search() {
    local pattern="$1"
    local todo_cmd=''
    if [ "$EDITOR" = "vim" ] || [ "$EDITOR" = "nvim" ] && [ -n "$pattern" ]; then
        todo_cmd="+'/$pattern' +'norm! n'"
    fi
    echo "$todo_cmd"
}

generate_editor_command_for_todos() {
    local todo_cmd=''
    if [ "$EDITOR" = "vim" ] || [ "$EDITOR" = "nvim" ]; then
        todo_cmd="+'/ ]' +'norm! n'"
    fi
    echo "$todo_cmd"
}

test_root_directory_fallback() {
    local function_type="$1"
    local expected_dir="$2"

    local result
    case "$function_type" in
    "notes")
        result=$(test_notes_root_directory)
        ;;
    "todos")
        result=$(test_todos_root_directory)
        ;;
    "count_pending")
        result=$(test_count_pending_root_directory)
        ;;
    esac

    assert_equal "$result" "$expected_dir"
}

test_notes_root_directory() {
    local root="$NOTES_DIR"
    echo "$root"
}

test_todos_root_directory() {
    local root="${TODOS_DIR:-$NOTES_DIR}"
    echo "$root"
}

test_count_pending_root_directory() {
    local root="${TODOS_DIR:-$NOTES_DIR}"
    echo "$root"
}

create_test_todo_file() {
    local file_path="$1"
    mkdir -p "$(dirname "$file_path")"
    cat >"$file_path" <<EOF
- [ ] Test task
EOF
}

create_test_content_structure() {
    mkdir -p "$NOTES_DIR/notes/tech"
    cat >"$NOTES_DIR/notes/vim-tips.md" <<EOF
# Vim Tips
Some useful vim shortcuts and techniques.
Advanced editing features.
EOF

    cat >"$NOTES_DIR/notes/tech/docker.md" <<EOF
# Docker Notes
Container management and deployment.
Docker compose configurations.
EOF

    mkdir -p "$TODOS_DIR/todos/2025/07"
    cat >"$TODOS_DIR/todos/2025/07/project.md" <<EOF
# Project Tasks
- [x] Setup repository
- [ ] Write documentation
- [ ] Add tests
- [ ] Deploy to production
EOF

    cat >"$TODOS_DIR/todos/2025/07/personal.md" <<EOF
# Personal Tasks
- [ ] Buy groceries
- [x] Call dentist
- [ ] Fix bike
EOF
}
