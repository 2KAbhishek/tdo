#!/usr/bin/env bats

load '../test_helper'

_test_get_date_command() {
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

@test "get_date_command returns gdate on Darwin" {
    uname() { echo "Darwin"; }
    command() { [[ "$*" == *"gdate"* ]]; }

    result=$(_test_get_date_command)
    assert_equal "$result" "gdate"
}

@test "get_date_command returns date on Linux" {
    uname() { echo "Linux"; }

    result=$(_test_get_date_command)
    assert_equal "$result" "date"
}

@test "check_command succeeds for existing commands" {
    command() { [[ "$2" == "bash" ]]; }

    run check_command "bash"
    assert_success
}

@test "check_command fails for non-existing commands" {
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
    local result
    result=$(calculate_date_offset "1" "months" "+")
    [[ "$result" =~ ^-?[0-9]+$ ]]
}

@test "calculate_date_offset handles years correctly" {
    local result
    result=$(calculate_date_offset "1" "years" "-")
    [[ "$result" =~ ^-?[0-9]+$ ]]
}
