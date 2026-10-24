#!/usr/bin/env bats

load '../test_helper'

@test "tdo e creates today's journal entry" {
    run_tdo_non_interactive "e"
    assert_success

    expected_file="$JOURNAL_DIR/entries/2025/07/2025-07-18.md"
    assert_file_exists "$expected_file"
}

@test "tdo e with date creates entry for that date" {
    run_tdo_non_interactive "e" "tomorrow"
    assert_success

    expected_file="$JOURNAL_DIR/entries/2025/07/2025-07-19.md"
    assert_file_exists "$expected_file"
}

@test "tdo e with date and title creates titled entry" {
    run_tdo_non_interactive "e" "tomorrow" "sprint-retro"
    assert_success

    expected_file="$JOURNAL_DIR/entries/2025/07/2025-07-19-sprint-retro.md"
    assert_file_exists "$expected_file"
}

@test "tdo e with title only creates today's titled entry" {
    run_tdo_non_interactive "e" "team-standup"
    assert_success

    expected_file="$JOURNAL_DIR/entries/2025/07/2025-07-18-team-standup.md"
    assert_file_exists "$expected_file"
}

@test "tdo e -m logs message to today's entry" {
    run_tdo_non_interactive "e" "-m" "Went for a 5k run"
    assert_success

    expected_file="$JOURNAL_DIR/entries/2025/07/2025-07-18.md"
    assert_file_exists "$expected_file"
    assert_contains "$(cat "$expected_file")" "- Went for a 5k run"
}

@test "tdo e -m with date logs message to specified date entry" {
    run_tdo_non_interactive "e" "-m" "Finished reading book" "yesterday"
    assert_success

    expected_file="$JOURNAL_DIR/entries/2025/07/2025-07-17.md"
    assert_file_exists "$expected_file"
    assert_contains "$(cat "$expected_file")" "- Finished reading book"
}

@test "tdo e date -m logs message" {
    run_tdo_non_interactive "e" "tomorrow" "-m" "Plan weekly milestones"
    assert_success

    expected_file="$JOURNAL_DIR/entries/2025/07/2025-07-19.md"
    assert_file_exists "$expected_file"
    assert_contains "$(cat "$expected_file")" "- Plan weekly milestones"
}

@test "tdo em shorthand logs message to today's entry" {
    run_tdo_non_interactive "em" "Had coffee with mentor"
    assert_success

    expected_file="$JOURNAL_DIR/entries/2025/07/2025-07-18.md"
    assert_file_exists "$expected_file"
    assert_contains "$(cat "$expected_file")" "- Had coffee with mentor"
}

@test "tdo -m adds daily todo to today's todo file" {
    run_tdo_non_interactive "-m" "Buy groceries"
    assert_success

    expected_file="$TODOS_DIR/todos/2025/07/2025-07-18.md"
    assert_file_exists "$expected_file"
    assert_contains "$(cat "$expected_file")" "- [ ] Buy groceries"
}

@test "tdo date -m adds daily todo to specified date" {
    run_tdo_non_interactive "tomorrow" "-m" "Submit tax documents"
    assert_success

    expected_file="$TODOS_DIR/todos/2025/07/2025-07-19.md"
    assert_file_exists "$expected_file"
    assert_contains "$(cat "$expected_file")" "- [ ] Submit tax documents"
}

@test "tdo t -m adds daily todo" {
    run_tdo_non_interactive "t" "-m" "Call dentist"
    assert_success

    expected_file="$TODOS_DIR/todos/2025/07/2025-07-18.md"
    assert_file_exists "$expected_file"
    assert_contains "$(cat "$expected_file")" "- [ ] Call dentist"
}

@test "tdo e list and el list entries in entries directory" {
    mkdir -p "$JOURNAL_DIR/entries/2025/07"
    touch "$JOURNAL_DIR/entries/2025/07/2025-07-17.md"
    touch "$JOURNAL_DIR/entries/2025/07/2025-07-18.md"

    INTERACTIVE=false run tdo "e" "list"
    assert_success
    assert_contains "$output" "2025-07-18.md"
    assert_contains "$output" "2025-07-17.md"
    # Ensure full absolute paths are not displayed, only sorted file names
    assert_not_contains "$output" "$JOURNAL_DIR"
    assert_not_contains "$output" "entries/2025"
    assert_equal "${lines[0]}" "2025-07-18.md"
    assert_equal "${lines[1]}" "2025-07-17.md"

    INTERACTIVE=false run tdo "el"
    assert_success
    assert_contains "$output" "2025-07-18.md"
    assert_not_contains "$output" "$JOURNAL_DIR"
    assert_equal "${lines[0]}" "2025-07-18.md"
}

@test "tdo e f and ef search journal entries" {
    mkdir -p "$JOURNAL_DIR/entries/2025/07"
    echo "Had a great workout session" > "$JOURNAL_DIR/entries/2025/07/2025-07-16.md"
    echo "Focused on code refactoring" > "$JOURNAL_DIR/entries/2025/07/2025-07-17.md"

    INTERACTIVE=false run tdo "e" "f" "workout"
    assert_success
    assert_equal "$output" "2025-07-16.md"
    assert_not_contains "$output" "$JOURNAL_DIR"

    INTERACTIVE=false run tdo "ef" "refactoring"
    assert_success
    assert_equal "$output" "2025-07-17.md"
    assert_not_contains "$output" "$JOURNAL_DIR"
}

@test "tdo e with custom JOURNAL_DIR stores entries under entries subfolder" {
    local custom_journal="$TEST_DIR/my_journal"
    export JOURNAL_DIR="$custom_journal"

    run_tdo_non_interactive "e" "today"
    assert_success

    expected_file="$custom_journal/entries/2025/07/2025-07-18.md"
    assert_file_exists "$expected_file"
    # Verify template was copied from NOTES_DIR fallback
    assert_contains "$(cat "$expected_file")" "# Entry Template"
}
