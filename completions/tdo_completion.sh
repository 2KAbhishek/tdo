#!/usr/bin/env bash
# TDO Tab Completions for Zsh and Bash
# shellcheck disable=SC2034,SC2128,SC2086,SC2154,SC2207,SC2015

if [ -n "$ZSH_VERSION" ]; then
    _tdo_zsh_completions() {
        local -a flags subcommands dates notes

        flags=(
            '-c:Commit changes'
            '--commit:Commit changes'
            '-e:Create or open journal entry'
            '--entry:Create or open journal entry'
            '-f:Search notes'
            '--find:Search notes'
            '-h:Show help'
            '--help:Show help'
            '-m:Quickly add todo item'
            '--message:Quickly add todo item'
            '-n:Create draft note'
            '--note:Create draft note'
            '-p:Show count of pending todos'
            '--pending:Show count of pending todos'
            '-t:Show pending todos'
            '--todo:Show pending todos'
        )

        subcommands=(
            'c:Commit changes'
            'commit:Commit changes'
            'e:Create or open journal entry'
            'entry:Create or open journal entry'
            'ef:Search journal entries'
            'el:List journal entries'
            'em:Quickly append message to journal'
            'f:Search notes'
            'find:Search notes'
            'h:Show help'
            'help:Show help'
            'n:Create draft note'
            'note:Create draft note'
            'p:Show count of pending todos'
            'pending:Show count of pending todos'
            't:Show pending todos'
            'todo:Show pending todos'
        )

        dates=(
            'today:Today'
            'tomorrow:Tomorrow'
            'yesterday:Yesterday'
            'next-week:Next week'
            'last-week:Last week'
            'monday:Monday'
            'tuesday:Tuesday'
            'wednesday:Wednesday'
            'thursday:Thursday'
            'friday:Friday'
            'saturday:Saturday'
            'sunday:Sunday'
        )

        if (( CURRENT == 2 )); then
            _describe -O -V -t flags 'flags' flags
            _describe -V -t subcommands 'commands' subcommands
            _describe -V -t dates 'dates' dates
            if [[ -n "$NOTES_DIR" && -d "$NOTES_DIR" ]]; then
                local notes_dir="$NOTES_DIR"
                [[ -d "$NOTES_DIR/notes" ]] && notes_dir="$NOTES_DIR/notes"
                notes=($(find "$notes_dir" -type f -name '*.md' -not -path '*/.*' | sed 's|.*/||' | sort -u))
                _describe -V -t notes 'notes' notes
            fi
        elif (( CURRENT == 3 )) && [[ "${words[2]}" == "e" || "${words[2]}" == "entry" ]]; then
            local -a entry_flags entry_cmds entry_dates entry_files
            entry_flags=(
                '-f:Search journal entries'
                '--find:Search journal entries'
                '-l:List journal entries'
                '--list:List journal entries'
                '-m:Quick log message'
            )
            entry_cmds=(
                'f:Search journal entries'
                'find:Search journal entries'
                'l:List journal entries'
                'list:List journal entries'
            )
            entry_dates=(
                'today:Today'
                'tomorrow:Tomorrow'
                'yesterday:Yesterday'
                'next-week:Next week'
                'last-week:Last week'
                'monday:Monday'
                'tuesday:Tuesday'
                'wednesday:Wednesday'
                'thursday:Thursday'
                'friday:Friday'
                'saturday:Saturday'
                'sunday:Sunday'
            )
            _describe -O -V -t flags 'flags' entry_flags
            _describe -V -t entry_cmds 'journal commands' entry_cmds
            _describe -V -t dates 'dates' entry_dates
            local journal_dir="${JOURNAL_DIR:-$NOTES_DIR}"
            [[ -d "$journal_dir/entries" ]] && journal_dir="$journal_dir/entries"
            if [[ -n "$journal_dir" && -d "$journal_dir" ]]; then
                entry_files=($(find "$journal_dir" -type f -name '*.md' -not -path '*/.*' | sed 's|.*/||' | sort -u))
                _describe -V -t entries 'journal entries' entry_files
            fi
        fi
    }

    if ! command -v compdef >/dev/null 2>&1; then
        autoload -Uz compinit && compinit -C 2>/dev/null || compinit 2>/dev/null
    fi

    zstyle ':completion:*:*tdo:*' group-order flags commands 'journal commands' dates entries notes
    zstyle ':completion:*:*tdo:*' sort false
    zstyle ':fzf-tab:complete:tdo:*' sort false

    compdef _tdo_zsh_completions tdo 2>/dev/null
elif [ -n "$BASH_VERSION" ]; then
    _tdo_bash_completions() {
        local cur prev opts
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"

        if [[ "$COMP_CWORD" -eq 1 ]]; then
            local bash_flags="-c --commit -e --entry -f --find -h --help -m --message -n --note -p --pending -t --todo"
            local bash_cmds="c commit e entry ef el em f find h help n note p pending t todo"
            local bash_dates="today tomorrow yesterday next-week last-week monday tuesday wednesday thursday friday saturday sunday"
            opts="$bash_flags $bash_cmds $bash_dates"
            if [[ -n "$NOTES_DIR" && -d "$NOTES_DIR" ]]; then
                local notes_dir="$NOTES_DIR"
                [[ -d "$NOTES_DIR/notes" ]] && notes_dir="$NOTES_DIR/notes"
                local note_files
                note_files=$(find "$notes_dir" -type f -name '*.md' -not -path '*/\.*' | sed 's|.*/||' | sort -u)
                opts="$opts $note_files"
            fi
            COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
        elif [[ "$COMP_CWORD" -eq 2 && ( "$prev" == "e" || "$prev" == "entry" ) ]]; then
            local bash_entry_flags="-f --find -l --list -m"
            local bash_entry_cmds="f find l list"
            local bash_entry_dates="today tomorrow yesterday next-week last-week monday tuesday wednesday thursday friday saturday sunday"
            opts="$bash_entry_flags $bash_entry_cmds $bash_entry_dates"
            local journal_dir="${JOURNAL_DIR:-$NOTES_DIR}"
            [[ -d "$journal_dir/entries" ]] && journal_dir="$journal_dir/entries"
            if [[ -n "$journal_dir" && -d "$journal_dir" ]]; then
                local entry_files
                entry_files=$(find "$journal_dir" -type f -name '*.md' -not -path '*/\.*' | sed 's|.*/||' | sort -u)
                opts="$opts $entry_files"
            fi
            COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
        fi
        return 0
    }

    complete -o nosort -F _tdo_bash_completions tdo 2>/dev/null || complete -F _tdo_bash_completions tdo
fi
