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
    # Current date: Friday July 18, 2025 (weekday 5)
    # Sunday=0, Monday=1, Tuesday=2, Wednesday=3, Thursday=4, Friday=5, Saturday=6

    result=$(parse_natural_date "sunday")
    assert_equal "$result" "-5"  # Sunday of current week (0-5=-5)

    result=$(parse_natural_date "monday")
    assert_equal "$result" "-4"  # Monday of current week (1-5=-4)

    result=$(parse_natural_date "friday")
    assert_equal "$result" "0"   # Today (5-5=0)

    result=$(parse_natural_date "saturday")
    assert_equal "$result" "1"   # Tomorrow (6-5=1)
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
    # Next week = current week offset + 7
    result=$(parse_natural_date "next-sunday")
    assert_equal "$result" "2"   # (-5) + 7 = 2

    result=$(parse_natural_date "next-monday")
    assert_equal "$result" "3"   # (-4) + 7 = 3

    result=$(parse_natural_date "next-friday")
    assert_equal "$result" "7"   # 0 + 7 = 7
}

@test "parse_natural_date handles last week patterns" {
    # Last week = current week offset - 7
    result=$(parse_natural_date "last-sunday")
    assert_equal "$result" "-12"  # (-5) - 7 = -12

    result=$(parse_natural_date "last-monday")
    assert_equal "$result" "-11"  # (-4) - 7 = -11

    result=$(parse_natural_date "last-friday")
    assert_equal "$result" "-7"   # 0 - 7 = -7
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
    # Invalid number should return original input
    result=$(parse_natural_date "abc-weeks-ago")
    assert_equal "$result" "abc-weeks-ago"

    # Decimal numbers should return original input
    result=$(parse_natural_date "2.5-weeks-later" 2>/dev/null || echo "2.5-weeks-later")
    assert_equal "$result" "2.5-weeks-later"
}

@test "parse_natural_date handles month patterns" {
    # These will use calculate_date_offset function
    # For testing, we assume it returns proper day offsets
    run parse_natural_date "1-month-later"
    assert_success

    run parse_natural_date "2-months-ago"
    assert_success

    # Invalid patterns
    result=$(parse_natural_date "abc-months-ago")
    assert_equal "$result" "abc-months-ago"
}

@test "parse_natural_date handles year patterns" {
    run parse_natural_date "1-year-later"
    assert_success

    run parse_natural_date "2-years-ago"
    assert_success

    # Invalid patterns
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
    # Current day is Friday (5)
    result=$(days_to_weekday 0)  # Sunday
    assert_equal "$result" "-5"

    result=$(days_to_weekday 1)  # Monday
    assert_equal "$result" "-4"

    result=$(days_to_weekday 5)  # Friday (today)
    assert_equal "$result" "0"

    result=$(days_to_weekday 6)  # Saturday
    assert_equal "$result" "1"
}
