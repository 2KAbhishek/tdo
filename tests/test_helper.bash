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

    # Source the main script without executing main function
    export BATS_TESTING=true

    # Create a test version of the script without the main execution
    local test_script="$TEST_DIR/tdo_test.sh"

    local script_path
    if [[ "$BATS_TEST_DIRNAME" == */unit ]]; then
        script_path="$BATS_TEST_DIRNAME/../../tdo.sh"
    elif [[ "$BATS_TEST_DIRNAME" == */integration ]]; then
        script_path="$BATS_TEST_DIRNAME/../../tdo.sh"
    else
        script_path="$BATS_TEST_DIRNAME/../tdo.sh"
    fi

    # Remove the last line (main "$@") and source the result
    sed '$d' "$script_path" >"$test_script"
    source "$test_script"

    # Load bats helper functions if available
    if command -v bats-assert &>/dev/null; then
        load "$(bats-assert)"
    fi

    # Override date functions for testing
    get_date_command() {
        echo "mock_date"
    }

    # Mock date command that uses our test date
    mock_date() {
        # Handle arguments based on first parameter
        case "$1" in
        "+%w")
            echo "$MOCK_WEEKDAY"
            ;;
        "+%Y")
            echo "2025"
            ;;
        "+%m")
            echo "07"
            ;;
        "+%d")
            echo "18"
            ;;
        "+%Y-%m-%d")
            echo "$MOCK_DATE"
            ;;
        -d)
            # Handle -d option with date and format
            local date_spec="$2"
            local format="$3"

            if [[ "$date_spec" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                # Absolute date format like "2025-06-30"
                case "$format" in
                "+%Y") echo "${date_spec:0:4}" ;;
                "+%m") echo "${date_spec:5:2}" ;;
                "+%d") echo "${date_spec:8:2}" ;;
                "+%Y-%m-%d") echo "$date_spec" ;;
                "+%s")
                    # Calculate epoch time for the given date
                    if command -v date >/dev/null 2>&1; then
                        date -d "$date_spec" +%s 2>/dev/null || echo "1721260800" # Default epoch for 2025-07-18
                    else
                        echo "1721260800" # Default epoch for 2025-07-18
                    fi
                    ;;
                *) echo "$date_spec" ;;
                esac
            elif [[ "$date_spec" =~ ^-?[0-9]+\ days$ ]]; then
                # Relative days format like "5 days", "-3 days"
                local days="${date_spec%% *}"

                local target_date

                # Calculate target date using appropriate date command for accuracy
                if [ "$(uname)" = "Darwin" ] && command -v gdate >/dev/null 2>&1; then
                    target_date=$(gdate -d "$MOCK_DATE + $days days" "+%Y-%m-%d" 2>/dev/null)
                elif [ "$(uname)" = "Darwin" ]; then
                    # Fallback calculation for macOS native date
                    local epoch=$(date -j -f "%Y-%m-%d" "$MOCK_DATE" "+%s" 2>/dev/null || echo "1721260800")
                    local days_seconds=$((days * 86400))
                    local target_epoch=$((epoch + days_seconds))
                    target_date=$(date -j -f "%s" "$target_epoch" "+%Y-%m-%d" 2>/dev/null)
                else
                    target_date=$(date -d "$MOCK_DATE + $days days" "+%Y-%m-%d" 2>/dev/null)
                fi

                if [[ -n "$target_date" ]]; then
                    case "$format" in
                    "+%Y") echo "${target_date:0:4}" ;;
                    "+%m") echo "${target_date:5:2}" ;;
                    "+%d") echo "${target_date:8:2}" ;;
                    "+%Y-%m-%d") echo "$target_date" ;;
                    "+%s")
                        if command -v date >/dev/null 2>&1; then
                            date -d "$target_date" +%s 2>/dev/null || echo "1721260800"
                        else
                            echo "1721260800"
                        fi
                        ;;
                    *) echo "$target_date" ;;
                    esac
                else
                    # Fallback to mock date if calculation fails
                    case "$format" in
                    "+%Y") echo "2025" ;;
                    "+%m") echo "07" ;;
                    "+%d") echo "18" ;;
                    "+%Y-%m-%d") echo "$MOCK_DATE" ;;
                    *) echo "$MOCK_DATE" ;;
                    esac
                fi
            else
                # Unknown date spec, return mock date
                case "$format" in
                "+%Y") echo "2025" ;;
                "+%m") echo "07" ;;
                "+%d") echo "18" ;;
                "+%Y-%m-%d") echo "$MOCK_DATE" ;;
                *) echo "$MOCK_DATE" ;;
                esac
            fi
            ;;
        *)
            # Default case - return mock date
            echo "$MOCK_DATE"
            ;;
        esac
    }
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
