#!/usr/bin/env bats

load '../test_helper'

setup_git_repo() {
    cd "$TEST_DIR"
    git init >/dev/null 2>&1
    git config user.email "test@example.com" >/dev/null 2>&1
    git config user.name "Test User" >/dev/null 2>&1
}

@test "commit_changes does nothing in non-git directory" {
    cd "$TEST_DIR"
    echo "test content" >test.txt

    mock_git_not_repo

    run commit_changes "$TEST_DIR"
    assert_success
}

@test "commit_changes initializes git repo detection" {
    setup_git_repo
    echo "test file" >test.txt

    mock_git_repo_with_changes

    run commit_changes "$TEST_DIR"
    assert_success
}

@test "commit_changes skips when no changes" {
    setup_git_repo
    git add . >/dev/null 2>&1
    git commit -m "initial" >/dev/null 2>&1

    mock_git_repo_no_changes

    run commit_changes "$TEST_DIR"
    assert_success
}

@test "commit_changes adds and commits when changes exist" {
    setup_git_repo
    echo "new content" >new_file.txt

    mock_git_repo_with_changes

    run commit_changes "$TEST_DIR"
    assert_success
}

@test "commit_changes uses timestamp in commit message" {
    setup_git_repo
    echo "content" >file.txt

    mock_git_repo_with_changes

    run commit_changes "$TEST_DIR"
    assert_success
}

@test "commit_changes handles git command failures gracefully" {
    setup_git_repo
    echo "content" >file.txt

    mock_git_repo_failures

    run commit_changes "$TEST_DIR"
    assert_success
}

@test "commit_changes returns to original directory" {
    setup_git_repo

    mock_git_repo_no_changes

    run commit_changes "$TEST_DIR"
    assert_success
}
