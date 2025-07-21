#!/usr/bin/env bats

load '../test_helper'

@test "todo command execution works" {
    create_test_todo_file "$TODOS_DIR/todos/2025/07/test.md"

    run tdo "t"
    assert_success
}

@test "todo with --todo flag works" {
    create_test_todo_file "$TODOS_DIR/todos/2025/07/test.md"

    run tdo "--todo"
    assert_success
}

@test "pending command execution works" {
    run tdo "p"
    assert_success
}

@test "pending with --pending flag works" {
    run tdo "--pending"
    assert_success
}

@test "count_pending_todos uses correct root directory fallback" {
    test_root_directory_fallback "count_pending" "$NOTES_DIR"
}

@test "pending_todos with vim editor sets search command" {
    test_editor_command_generation "vim" " ]" "+'/ ]' +'norm! n'"
}

@test "pending_todos with nvim editor sets search command" {
    test_editor_command_generation "nvim" " ]" "+'/ ]' +'norm! n'"
}

@test "pending_todos with other editors does not set search command" {
    test_editor_command_generation "nano" " ]" ""
}

@test "pending_todos uses correct root directory" {
    unset TODOS_DIR
    test_root_directory_fallback "todos" "$NOTES_DIR"
}
