#!/usr/bin/env bats

load '../test_helper'

setup_test_content() {
    create_test_content_structure
}

@test "tdo find command searches for content" {
    setup_test_content

    run tdo "f" "vim"
    assert_success
    echo "$output" | grep -q "vim-tips.md"
}

@test "tdo find command with --find flag works" {
    setup_test_content

    run tdo "--find" "docker"
    assert_success
    echo "$output" | grep -q "tech/docker.md"
}

@test "tdo find command finds nothing for non-existent term" {
    setup_test_content

    run tdo "f" "nonexistent-term"
    assert_success
    [[ -z "$output" ]]
}

@test "tdo todo command lists pending todos" {
    setup_test_content

    run tdo "t"
    assert_success
    echo "$output" | grep -q "project.md"
    echo "$output" | grep -q "personal.md"
}

@test "tdo todo command with --todo flag works" {
    setup_test_content

    run tdo "--todo"
    assert_success
    echo "$output" | grep -q "project.md"
}

@test "tdo pending command counts pending todos correctly" {
    setup_test_content

    run tdo "p"
    assert_success
    assert_equal "$output" "5"
}

@test "tdo pending command with --pending flag works" {
    setup_test_content

    run tdo "--pending"
    assert_success
    assert_equal "$output" "5"
}

@test "tdo commit command works in git directory" {
    cd "$TEST_DIR"
    git init >/dev/null 2>&1
    git config user.email "test@example.com" >/dev/null 2>&1
    git config user.name "Test User" >/dev/null 2>&1

    echo "test content" >test.txt

    mock_git_repo_with_changes

    run tdo "c" "$TEST_DIR"
    assert_success
}

@test "tdo commit command with --commit flag works" {
    cd "$TEST_DIR"

    mock_git_not_repo

    run tdo "--commit" "$TEST_DIR"
    assert_success
}

@test "tdo find excludes template files from search" {
    mkdir -p "$NOTES_DIR/templates"
    echo "vim configuration" >"$NOTES_DIR/templates/template.md"
    echo "vim tips and tricks" >"$NOTES_DIR/notes/vim.md"

    run tdo "f" "vim"
    assert_success
    echo "$output" | grep -q "vim.md"
    ! echo "$output" | grep -q "template.md"
}

@test "tdo todo finds todos in subdirectories" {
    mkdir -p "$TODOS_DIR/todos/2025/08"
    cat >"$TODOS_DIR/todos/2025/08/future.md" <<EOF
# Future Tasks
- [ ] Plan vacation
- [ ] Update resume
EOF

    run tdo "t"
    assert_success
    echo "$output" | grep -q "future.md"
}

@test "tdo pending count is zero when no pending todos" {
    mkdir -p "$TODOS_DIR/todos/2025/07"
    cat >"$TODOS_DIR/todos/2025/07/done.md" <<EOF
# Completed Tasks
- [x] Task 1
- [x] Task 2
EOF

    run tdo "p"
    assert_success
    assert_equal "$output" "0"
}
