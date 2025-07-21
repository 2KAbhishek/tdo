#!/usr/bin/env bats

load '../test_helper'

@test "find_note command execution works" {
    run tdo "f" "test"
    assert_success
}

@test "find_note with --find flag works" {
    run tdo "--find" "test"
    assert_success
}

@test "find_note uses NOTES_DIR as root directory" {
    test_root_directory_fallback "notes" "$NOTES_DIR"
}

@test "find_note with vim editor sets search command" {
    test_editor_command_generation "vim" "test" "+'/test' +'norm! n'"
}

@test "find_note with nvim editor sets search command" {
    test_editor_command_generation "nvim" "pattern" "+'/pattern' +'norm! n'"
}

@test "find_note with other editors does not set search command" {
    test_editor_command_generation "nano" "pattern" ""
}
