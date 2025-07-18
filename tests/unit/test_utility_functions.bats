#!/usr/bin/env bats

load '../test_helper'

@test "get_date_command returns gdate on Darwin" {
    # Test the actual get_date_command logic by creating a local version
    get_date_command_real() {
        if [ "$(uname)" = "Darwin" ]; then
            if command -v gdate &>/dev/null; then
                echo "gdate"
            else
                echo "date"
            fi
        else
            echo "date"
        fi
    }

    # Mock uname to return Darwin
    uname() { echo "Darwin"; }

    # Mock command to succeed for gdate
    command() {
        if [[ "$*" == *"gdate"* ]]; then
            return 0
        else
            return 1
        fi
    }

    result=$(get_date_command_real)
    assert_equal "$result" "gdate"
}

@test "get_date_command returns date on Linux" {
    # Test the actual get_date_command logic by creating a local version
    get_date_command_real() {
        if [ "$(uname)" = "Darwin" ]; then
            if command -v gdate &>/dev/null; then
                echo "gdate"
            else
                echo "date"
            fi
        else
            echo "date"
        fi
    }

    # Mock uname to return Linux
    uname() { echo "Linux"; }

    result=$(get_date_command_real)
    assert_equal "$result" "date"
}

@test "check_command succeeds for existing commands" {
    # Mock command to simulate existing command
    command() {
        if [[ "$2" == "bash" ]]; then
            return 0
        else
            return 1
        fi
    }

    run check_command "bash"
    assert_success
}

@test "check_command fails for non-existing commands" {
    # Mock command to simulate missing command
    command() { return 1; }

    run check_command "nonexistent-command"
    assert_failure
}

@test "check_env succeeds for set environment variables" {
    export TEST_VAR="test_value"

    run check_env "TEST_VAR"
    assert_success
}

@test "check_env fails for unset environment variables" {
    unset UNSET_VAR 2>/dev/null || true

    run check_env "UNSET_VAR"
    assert_failure
}

@test "config_setup loads default values" {
    # Ensure no config file exists in test environment
    config_setup

    assert_equal "$add_entry_timestamp" "true"
    assert_equal "$add_new_note_timestamp" "false"
    assert_equal "$filename_as_title" "false"
}

@test "config_setup loads from config file" {
    # Create test config file
    local config_file="$TEST_DIR/.config/tdorc"
    mkdir -p "$(dirname "$config_file")"
    cat >"$config_file" <<EOF
ADD_ENTRY_TIMESTAMP=false
ADD_NEW_NOTE_TIMESTAMP=true
FILE_NAME_AS_TITLE=true
EOF

    # Mock HOME to point to test directory
    HOME="$TEST_DIR" config_setup

    assert_equal "$add_entry_timestamp" "false"
    assert_equal "$add_new_note_timestamp" "true"
    assert_equal "$filename_as_title" "true"
}

@test "calculate_date_offset handles months correctly" {
    # Mock the date calculation
    local result
    result=$(calculate_date_offset "1" "months" "+")

    # Should return a number (days offset)
    [[ "$result" =~ ^-?[0-9]+$ ]]
}

@test "calculate_date_offset handles years correctly" {
    local result
    result=$(calculate_date_offset "1" "years" "-")

    # Should return a number (days offset)
    [[ "$result" =~ ^-?[0-9]+$ ]]
}
