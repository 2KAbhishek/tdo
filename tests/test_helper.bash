#!/usr/bin/env bash

# Test helper functions for tdo.sh unit tests

# Setup test environment
setup() {
    # Create temporary test environment
    export TEST_DIR="/tmp/tdo_test_$$"
    export NOTES_DIR="$TEST_DIR/notes"
    export TODOS_DIR="$TEST_DIR/notes"
    export JOURNAL_DIR="$TEST_DIR/notes"
    export EDITOR="echo" # Mock editor for non-interactive testing

    # Create test directory structure
    mkdir -p "$NOTES_DIR"/{notes,todos,entries,templates}

    # Create basic templates
    echo "# Todo Template" >"$NOTES_DIR/templates/todo.md"
    echo "# Note Template" >"$NOTES_DIR/templates/note.md"
    echo "# Entry Template" >"$NOTES_DIR/templates/entry.md"

    # Mock current date for consistent testing (Friday July 18, 2025)
    export MOCK_DATE="2025-07-18"
    export MOCK_WEEKDAY="5" # Friday = 5
    export MOCK_YEAR="2025"
    export MOCK_MONTH="07"
    export MOCK_DAY="18"
    export MOCK_EPOCH="1721260800"

    # Source the main script without executing main function
    export BATS_TESTING=true

    # Create a test version of the script
    local test_script="$TEST_DIR/tdo_test.sh"
    local script_path

    if [[ "$BATS_TEST_DIRNAME" == */unit ]]; then
        script_path="$BATS_TEST_DIRNAME/../../tdo.sh"
    elif [[ "$BATS_TEST_DIRNAME" == */integration ]]; then
        script_path="$BATS_TEST_DIRNAME/../../tdo.sh"
    else
        script_path="$BATS_TEST_DIRNAME/../tdo.sh"
    fi

    # Copy script to test location
    cp "$script_path" "$test_script"

    # Source the script
    source "$test_script"

    # Load bats helper functions if available
    if command -v bats-assert &>/dev/null; then
        load "$(bats-assert)"
    fi

    # Setup all mocks and overrides
    setup_mocks
}

# Centralized mock setup function
setup_mocks() {
    # Date function overrides
    get_date_command() { echo "mock_date"; }
    date() { mock_date "$@"; }

    # Command mocks
    rg() { echo "Mock rg output"; }
    fzf() { echo "Mock fzf output"; }

    # Check command override (allows unit test mocks while providing defaults)
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

    # Write file override (prevent exit in tests)
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

    # TDO function wrapper
    tdo() { main "$@"; }

    # Mock date command with constants
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

# Date calculation helper functions
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
        -4) target_date="2025-07-14" ;;  # Monday
        -5) target_date="2025-07-13" ;;  # Sunday
        7) target_date="2025-07-25" ;;   # Next Friday
        -7) target_date="2025-07-11" ;;  # Last Friday
        14) target_date="2025-08-01" ;;  # 2 weeks later
        -11) target_date="2025-07-07" ;; # Last Monday
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

# Cleanup test environment
teardown() {
    if [[ -n "$TEST_DIR" && "$TEST_DIR" =~ ^/tmp/tdo_test_ ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# Test assertions
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

# Helper to run tdo in non-interactive mode
run_tdo_non_interactive() {
    INTERACTIVE=false tdo "$@"
}
