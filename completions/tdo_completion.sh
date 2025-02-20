#!/usr/bin/env bash

_tdo_completions() {
    local cur opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    opts=$(find "$NOTES_DIR" -mindepth 1 -not -path '*/\.*' | sed "s|^$NOTES_DIR/||")

    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
}

complete -F _tdo_completions tdo
