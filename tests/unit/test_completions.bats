#!/usr/bin/env bats

load '../test_helper'

@test "bash completions order CLI flags before file names on first argument" {
    mkdir -p "$NOTES_DIR/notes"
    touch "$NOTES_DIR/notes/alpha.md"
    touch "$NOTES_DIR/notes/zebra.md"

    # shellcheck source=/dev/null
    source "$BATS_TEST_DIRNAME/../../completions/tdo_completion.sh"

    COMP_WORDS=("tdo" "")
    COMP_CWORD=1
    _tdo_bash_completions

    # First completion must be a CLI flag starting with '-'
    assert_equal "${COMPREPLY[0]:0:1}" "-"

    # Find position of first file and last flag
    local first_file_idx=-1
    local last_flag_idx=-1
    for i in "${!COMPREPLY[@]}"; do
        if [[ "${COMPREPLY[$i]}" == *.md ]] && [[ "$first_file_idx" -eq -1 ]]; then
            first_file_idx="$i"
        fi
        if [[ "${COMPREPLY[$i]}" == -* ]]; then
            last_flag_idx="$i"
        fi
    done

    # All flags must appear before file names
    [ "$last_flag_idx" -lt "$first_file_idx" ]
}

@test "bash completions show only CLI flags when dash is typed" {
    # shellcheck source=/dev/null
    source "$BATS_TEST_DIRNAME/../../completions/tdo_completion.sh"

    COMP_WORDS=("tdo" "-")
    COMP_CWORD=1
    _tdo_bash_completions

    for item in "${COMPREPLY[@]}"; do
        assert_equal "${item:0:1}" "-"
    done

    # Verify key flags are present
    local all="${COMPREPLY[*]}"
    assert_contains "$all" "-c"
    assert_contains "$all" "-e"
    assert_contains "$all" "-m"
    assert_contains "$all" "--help"
}

@test "bash completions for tdo e order flags before entries" {
    mkdir -p "$JOURNAL_DIR/entries/2025/07"
    touch "$JOURNAL_DIR/entries/2025/07/2025-07-18.md"

    # shellcheck source=/dev/null
    source "$BATS_TEST_DIRNAME/../../completions/tdo_completion.sh"

    COMP_WORDS=("tdo" "e" "")
    COMP_CWORD=2
    _tdo_bash_completions

    assert_equal "${COMPREPLY[0]:0:1}" "-"

    COMP_WORDS=("tdo" "e" "-")
    COMP_CWORD=2
    _tdo_bash_completions

    local all="${COMPREPLY[*]}"
    assert_contains "$all" "-f"
    assert_contains "$all" "-l"
    assert_contains "$all" "-m"
}

@test "fish completions register CLI flags and entry flags" {
    if ! command -v fish >/dev/null 2>&1; then
        skip "fish shell not installed"
    fi

    run fish -c "source completions/tdo_completion.fish; complete -C'tdo -'"
    assert_success
    assert_contains "$output" "-c"
    assert_contains "$output" "-e"
    assert_contains "$output" "-m"
    assert_contains "$output" "--help"

    run fish -c "source completions/tdo_completion.fish; complete -C'tdo e -'"
    assert_success
    assert_contains "$output" "-f"
    assert_contains "$output" "-l"
    assert_contains "$output" "-m"
}
