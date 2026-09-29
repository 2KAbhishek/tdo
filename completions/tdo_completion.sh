#!/usr/bin/env bash
# TDO Tab Completions for Zsh and Bash

if [ -n "$ZSH_VERSION" ]; then
    _tdo_zsh_completions() {
        if [[ -n "$NOTES_DIR" && -d "$NOTES_DIR" ]]; then
            local notes_dir="$NOTES_DIR"
            [[ -d "$NOTES_DIR/notes" ]] && notes_dir="$NOTES_DIR/notes"

            local -a notes
            notes=(${(f)"$(find "$notes_dir" -type f -name '*.md' -not -path '*/.*' | sed 's|.*/||' | sort -u)"})
            _describe -t notes 'notes' notes
        fi
    }

    if ! command -v compdef >/dev/null 2>&1; then
        autoload -Uz compinit && compinit -C 2>/dev/null || compinit 2>/dev/null
    fi

    compdef _tdo_zsh_completions tdo 2>/dev/null
elif [ -n "$BASH_VERSION" ]; then
    _tdo_bash_completions() {
        local cur opts
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        if [[ -n "$NOTES_DIR" && -d "$NOTES_DIR" ]]; then
            local notes_dir="$NOTES_DIR"
            [[ -d "$NOTES_DIR/notes" ]] && notes_dir="$NOTES_DIR/notes"

            opts=$(find "$notes_dir" -type f -name '*.md' -not -path '*/\.*' | sed 's|.*/||' | sort -u)
            local IFS=$'\n'
            COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
        fi
        return 0
    }

    complete -F _tdo_bash_completions tdo
fi
