#!/usr/bin/env bats

load '../test_helper'

@test "generate_entry_file_path handles date only" {
    result=$(generate_entry_file_path "0")
    assert_equal "$result" "2025/07/2025-07-18.md"

    result=$(generate_entry_file_path "tomorrow")
    assert_equal "$result" "2025/07/2025-07-19.md"
}

@test "generate_entry_file_path handles date with title" {
    result=$(generate_entry_file_path "0" "retro")
    assert_equal "$result" "2025/07/2025-07-18-retro.md"

    result=$(generate_entry_file_path "tomorrow" "sprint-review")
    assert_equal "$result" "2025/07/2025-07-19-sprint-review.md"
}

@test "generate_entry_file_path converts spaces to hyphens in title" {
    result=$(generate_entry_file_path "0" "weekly retro notes")
    assert_equal "$result" "2025/07/2025-07-18-weekly-retro-notes.md"
}

@test "generate_entry_file_path returns failure for invalid date" {
    run generate_entry_file_path "invalid-date" "retro"
    assert_failure
}

@test "get_journal_root and get_entries_dir default to NOTES_DIR" {
    unset JOURNAL_DIR
    root=$(get_journal_root)
    entries_dir=$(get_entries_dir)

    assert_equal "$root" "$NOTES_DIR"
    assert_equal "$entries_dir" "$NOTES_DIR/entries"
}

@test "get_journal_root and get_entries_dir with custom JOURNAL_DIR" {
    export JOURNAL_DIR="/tmp/custom_journal"
    root=$(get_journal_root)
    entries_dir=$(get_entries_dir)

    assert_equal "$root" "/tmp/custom_journal"
    assert_equal "$entries_dir" "/tmp/custom_journal/entries"
}

@test "get_journal_root and get_entries_dir normalize path when JOURNAL_DIR ends in entries" {
    export JOURNAL_DIR="/tmp/custom_journal/entries"
    root=$(get_journal_root)
    entries_dir=$(get_entries_dir)

    assert_equal "$root" "/tmp/custom_journal"
    assert_equal "$entries_dir" "/tmp/custom_journal/entries"
}

@test "get_todos_root and get_todos_dir default to NOTES_DIR" {
    unset TODOS_DIR
    root=$(get_todos_root)
    todos_dir=$(get_todos_dir)

    assert_equal "$root" "$NOTES_DIR"
    assert_equal "$todos_dir" "$NOTES_DIR/todos"
}

@test "get_todos_root and get_todos_dir with custom TODOS_DIR" {
    export TODOS_DIR="/tmp/custom_todos"
    root=$(get_todos_root)
    todos_dir=$(get_todos_dir)

    assert_equal "$root" "/tmp/custom_todos"
    assert_equal "$todos_dir" "/tmp/custom_todos/todos"
}

@test "get_template falls back from custom root to NOTES_DIR" {
    local custom_root="$TEST_DIR/custom_root"
    mkdir -p "$custom_root"

    # Custom root has no template, NOTES_DIR has entry.md
    template=$(get_template "entry" "$custom_root")
    assert_equal "$template" "$NOTES_DIR/templates/entry.md"

    # When custom root has template, use custom root
    mkdir -p "$custom_root/templates"
    echo "# Custom Template" > "$custom_root/templates/entry.md"
    template=$(get_template "entry" "$custom_root")
    assert_equal "$template" "$custom_root/templates/entry.md"
}

@test "add_timestamp prevents duplicate consecutive timestamp headings" {
    local test_file="$TEST_DIR/test_timestamp.md"
    touch "$test_file"

    add_timestamp "$test_file" "## %a, %I:%M %p"
    initial_count=$(grep -c "## " "$test_file")
    assert_equal "$initial_count" "1"

    # Calling again without adding text should not duplicate the timestamp
    add_timestamp "$test_file" "## %a, %I:%M %p"
    duplicate_count=$(grep -c "## " "$test_file")
    assert_equal "$duplicate_count" "1"

    # Adding text then calling add_timestamp should add a new timestamp
    echo "Some entry content" >> "$test_file"
    add_timestamp "$test_file" "## %a, %I:%M %p"
    after_content_count=$(grep -c "## " "$test_file")
    assert_equal "$after_content_count" "2"
}
