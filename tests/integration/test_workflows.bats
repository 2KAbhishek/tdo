#!/usr/bin/env bats

load '../test_helper'

@test "tdo with no arguments creates today's todo" {
    run_tdo_non_interactive ""

    expected_file="$TODOS_DIR/todos/2025/07/2025-07-18.md"
    assert_file_exists "$expected_file"
}

@test "tdo with natural language creates correct todo file" {
    run_tdo_non_interactive "tomorrow"

    expected_file="$TODOS_DIR/todos/2025/07/2025-07-19.md"
    assert_file_exists "$expected_file"
}

@test "tdo with absolute date creates correct todo file" {
    run_tdo_non_interactive "2025-12-25"

    expected_file="$TODOS_DIR/todos/2025/12/2025-12-25.md"
    assert_file_exists "$expected_file"
}

@test "tdo with invalid date falls back to note creation" {
    run_tdo_non_interactive "project-planning"

    expected_file="$NOTES_DIR/notes/project-planning.md"
    assert_file_exists "$expected_file"
}

@test "tdo with note path creates note in correct location" {
    run_tdo_non_interactive "tech/vim-tips"

    expected_file="$NOTES_DIR/notes/tech/vim-tips.md"
    assert_file_exists "$expected_file"
    assert_dir_exists "$NOTES_DIR/notes/tech"
}

@test "tdo entry creates journal entry" {
    run_tdo_non_interactive "e"

    expected_file="$JOURNAL_DIR/entries/2025/07/2025-07-18.md"
    assert_file_exists "$expected_file"
}

@test "tdo entry with date creates correct journal file" {
    run_tdo_non_interactive "e" "tomorrow"

    expected_file="$JOURNAL_DIR/entries/2025/07/2025-07-19.md"
    assert_file_exists "$expected_file"
}

@test "tdo entry with invalid date falls back to note creation" {
    run_tdo_non_interactive "e" "invalid-date"

    expected_file="$NOTES_DIR/notes/invalid-date.md"
    assert_file_exists "$expected_file"
}

@test "tdo note creates draft note with timestamp" {
    run_tdo_non_interactive "n"

    draft_files=$(find "$NOTES_DIR/notes/drafts" -name "*.md" 2>/dev/null | wc -l)
    [[ "$draft_files" -gt 0 ]]
}

@test "tdo help displays help message" {
    run tdo "h"
    assert_success
    assert_contains "$output" "tdo: Fast & Simple Note Taking"
    assert_contains "$output" "Usage: tdo"
}

@test "tdo with command flags work correctly" {
    run tdo "p"
    assert_success
    assert_equal "$output" "0"
}

@test "templates are used when creating files" {
    run_tdo_non_interactive "test-note"

    expected_file="$NOTES_DIR/notes/test-note.md"
    assert_file_exists "$expected_file"

    content=$(cat "$expected_file")
    assert_contains "$content" "# Note Template"
}

@test "directory structure is created automatically" {
    run_tdo_non_interactive "2025-01-01"

    assert_dir_exists "$TODOS_DIR/todos/2025"
    assert_dir_exists "$TODOS_DIR/todos/2025/01"
    assert_file_exists "$TODOS_DIR/todos/2025/01/2025-01-01.md"
}

@test "weekday patterns work correctly in workflows" {
    run_tdo_non_interactive "monday"
    expected_file="$TODOS_DIR/todos/2025/07/2025-07-14.md"
    assert_file_exists "$expected_file"

    run_tdo_non_interactive "next-friday"
    expected_file="$TODOS_DIR/todos/2025/07/2025-07-25.md"
    assert_file_exists "$expected_file"
}

@test "complex date patterns work in journal entries" {
    run_tdo_non_interactive "e" "last-monday"
    expected_file="$JOURNAL_DIR/entries/2025/07/2025-07-07.md"
    assert_file_exists "$expected_file"

    run_tdo_non_interactive "e" "2-weeks-later"
    expected_file="$JOURNAL_DIR/entries/2025/08/2025-08-01.md"
    assert_file_exists "$expected_file"
}
