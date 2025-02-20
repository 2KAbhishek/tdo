#!/usr/bin/env bash

_tdo_completions() {
	local cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD - 1]}"
	opts=$(gfind "$NOTES_DIR" -type f -not -path '*/\.*' -printf '%P\n')

	COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
	return 0
}

complete -F _tdo_completions tdo
