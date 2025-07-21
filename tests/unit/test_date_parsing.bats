#!/usr/bin/env bats

load '../test_helper'

@test "parse_natural_date handles basic relative dates" {
    result=$(parse_natural_date "today")
    assert_equal "$result" "0"

    result=$(parse_natural_date "tomorrow")
    assert_equal "$result" "1"

    result=$(parse_natural_date "yesterday")
    assert_equal "$result" "-1"
}

@test "parse_natural_date handles case insensitivity" {
    result=$(parse_natural_date "TODAY")
    assert_equal "$result" "0"

    result=$(parse_natural_date "Tomorrow")
    assert_equal "$result" "1"

    result=$(parse_natural_date "YESTERDAY")
    assert_equal "$result" "-1"
}

@test "parse_natural_date handles weekdays in current week" {
    result=$(parse_natural_date "sunday")
    assert_equal "$result" "-5"

    result=$(parse_natural_date "monday")
    assert_equal "$result" "-4"

    result=$(parse_natural_date "friday")
    assert_equal "$result" "0"

    result=$(parse_natural_date "saturday")
    assert_equal "$result" "1"
}

@test "parse_natural_date handles short weekday forms" {
    result=$(parse_natural_date "sun")
    assert_equal "$result" "-5"

    result=$(parse_natural_date "mon")
    assert_equal "$result" "-4"

    result=$(parse_natural_date "fri")
    assert_equal "$result" "0"

    result=$(parse_natural_date "sat")
    assert_equal "$result" "1"
}

@test "parse_natural_date handles next week patterns" {
    result=$(parse_natural_date "next-sunday")
    assert_equal "$result" "2"

    result=$(parse_natural_date "next-monday")
    assert_equal "$result" "3"

    result=$(parse_natural_date "next-friday")
    assert_equal "$result" "7"
}

@test "parse_natural_date handles last week patterns" {
    result=$(parse_natural_date "last-sunday")
    assert_equal "$result" "-12"

    result=$(parse_natural_date "last-monday")
    assert_equal "$result" "-11"

    result=$(parse_natural_date "last-friday")
    assert_equal "$result" "-7"
}

@test "parse_natural_date handles short next/last forms" {
    result=$(parse_natural_date "next-sun")
    assert_equal "$result" "2"

    result=$(parse_natural_date "last-mon")
    assert_equal "$result" "-11"
}

@test "parse_natural_date handles quick aliases" {
    result=$(parse_natural_date "next-week")
    assert_equal "$result" "7"

    result=$(parse_natural_date "last-week")
    assert_equal "$result" "-7"

    result=$(parse_natural_date "next-month")
    assert_equal "$result" "30"

    result=$(parse_natural_date "last-month")
    assert_equal "$result" "-30"

    result=$(parse_natural_date "next-year")
    assert_equal "$result" "365"

    result=$(parse_natural_date "last-year")
    assert_equal "$result" "-365"
}

@test "parse_natural_date handles week patterns" {
    result=$(parse_natural_date "2-weeks-later")
    assert_equal "$result" "14"

    result=$(parse_natural_date "3-weeks-ago")
    assert_equal "$result" "-21"

    result=$(parse_natural_date "1-week-later")
    assert_equal "$result" "7"

    result=$(parse_natural_date "1-week-ago")
    assert_equal "$result" "-7"
}

@test "parse_natural_date handles invalid week patterns" {
    result=$(parse_natural_date "abc-weeks-ago")
    assert_equal "$result" "abc-weeks-ago"

    result=$(parse_natural_date "2.5-weeks-later" 2>/dev/null || echo "2.5-weeks-later")
    assert_equal "$result" "2.5-weeks-later"
}

@test "parse_natural_date handles month patterns" {
    run parse_natural_date "1-month-later"
    assert_success

    run parse_natural_date "2-months-ago"
    assert_success

    result=$(parse_natural_date "abc-months-ago")
    assert_equal "$result" "abc-months-ago"
}

@test "parse_natural_date handles year patterns" {
    run parse_natural_date "1-year-later"
    assert_success

    run parse_natural_date "2-years-ago"
    assert_success

    result=$(parse_natural_date "abc-years-ago")
    assert_equal "$result" "abc-years-ago"
}

@test "parse_natural_date returns original input for unmatched patterns" {
    result=$(parse_natural_date "invalid-date")
    assert_equal "$result" "invalid-date"

    result=$(parse_natural_date "2025-07-14")
    assert_equal "$result" "2025-07-14"

    result=$(parse_natural_date "some-random-text")
    assert_equal "$result" "some-random-text"
}

@test "days_to_weekday calculates correct offsets" {
    result=$(days_to_weekday 0)
    assert_equal "$result" "-5"

    result=$(days_to_weekday 1)
    assert_equal "$result" "-4"

    result=$(days_to_weekday 5)
    assert_equal "$result" "0"

    result=$(days_to_weekday 6)
    assert_equal "$result" "1"
}
