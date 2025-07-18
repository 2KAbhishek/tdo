#!/usr/bin/env bats

load '../test_helper'

@test "generate_file_path handles numeric day offsets" {
    result=$(generate_file_path "0")
    assert_equal "$result" "2025/07/2025-07-18.md"

    result=$(generate_file_path "1")
    assert_equal "$result" "2025/07/2025-07-19.md"

    result=$(generate_file_path "-1")
    assert_equal "$result" "2025/07/2025-07-17.md"
}

@test "generate_file_path handles absolute date format" {
    result=$(generate_file_path "2025-07-14")
    assert_equal "$result" "2025/07/2025-07-14.md"

    result=$(generate_file_path "2025-12-25")
    assert_equal "$result" "2025/12/2025-12-25.md"

    result=$(generate_file_path "2024-01-01")
    assert_equal "$result" "2024/01/2024-01-01.md"
}

@test "generate_file_path handles natural language dates" {
    result=$(generate_file_path "tomorrow")
    assert_equal "$result" "2025/07/2025-07-19.md"

    result=$(generate_file_path "yesterday")
    assert_equal "$result" "2025/07/2025-07-17.md"

    result=$(generate_file_path "monday")
    assert_equal "$result" "2025/07/2025-07-14.md"
}

@test "generate_file_path returns failure for invalid dates" {
    run generate_file_path "invalid-date-string"
    assert_failure

    run generate_file_path "not-a-date"
    assert_failure

    run generate_file_path "project-planning"
    assert_failure
}

@test "generate_file_path handles default parameter" {
    result=$(generate_file_path)
    assert_equal "$result" "2025/07/2025-07-18.md"
}

@test "generate_file_path handles edge case dates" {
    # Test month boundaries
    result=$(generate_file_path "2025-01-31")
    assert_equal "$result" "2025/01/2025-01-31.md"

    result=$(generate_file_path "2025-12-31")
    assert_equal "$result" "2025/12/2025-12-31.md"

    # Test leap year
    result=$(generate_file_path "2024-02-29")
    assert_equal "$result" "2024/02/2024-02-29.md"
}

@test "generate_file_path handles complex natural language" {
    result=$(generate_file_path "next-friday")
    assert_equal "$result" "2025/07/2025-07-25.md"

    result=$(generate_file_path "last-monday")
    assert_equal "$result" "2025/07/2025-07-07.md"
}
