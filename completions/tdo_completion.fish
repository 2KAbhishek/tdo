# TDO Fish Tab Completions

function __tdo_note_files
    set -l notes_dir "$NOTES_DIR"
    test -d "$NOTES_DIR/notes"; and set notes_dir "$NOTES_DIR/notes"
    if test -n "$notes_dir"; and test -d "$notes_dir"
        find "$notes_dir" -type f -name '*.md' -not -path '*/.*' | sed 's|.*/||' | sort -u
    end
end

function __tdo_journal_files
    set -l entries_dir "$JOURNAL_DIR"
    test -z "$entries_dir"; and set entries_dir "$NOTES_DIR"
    test -d "$entries_dir/entries"; and set entries_dir "$entries_dir/entries"
    if test -n "$entries_dir"; and test -d "$entries_dir"
        find "$entries_dir" -type f -name '*.md' -not -path '*/.*' | sed 's|.*/||' | sort -u
    end
end

# Disable default filesystem file completions
complete -c tdo -f

# CLI flags (short and long options)
complete -c tdo -s c -l commit -d "Commit changes in directory"
complete -c tdo -s e -l entry -d "Create or open journal entry"
complete -c tdo -s f -l find -d "Search notes"
complete -c tdo -s h -l help -d "Show help"
complete -c tdo -s m -l message -d "Quickly add todo item"
complete -c tdo -s n -l note -d "Create draft note"
complete -c tdo -s p -l pending -d "Count pending todos"
complete -c tdo -s t -l todo -d "Show pending todos"

# Subcommands
complete -c tdo -n "__fish_use_subcommand" -a "c commit" -d "Commit changes"
complete -c tdo -n "__fish_use_subcommand" -a "e entry" -d "Create/open journal entry"
complete -c tdo -n "__fish_use_subcommand" -a "ef" -d "Search journal entries"
complete -c tdo -n "__fish_use_subcommand" -a "el" -d "List journal entries"
complete -c tdo -n "__fish_use_subcommand" -a "em" -d "Quick log journal entry"
complete -c tdo -n "__fish_use_subcommand" -a "f find" -d "Search notes"
complete -c tdo -n "__fish_use_subcommand" -a "h help" -d "Show help"
complete -c tdo -n "__fish_use_subcommand" -a "n note" -d "Create draft note"
complete -c tdo -n "__fish_use_subcommand" -a "p pending" -d "Count pending todos"
complete -c tdo -n "__fish_use_subcommand" -a "t todo" -d "Show pending todos"

# Relative dates
complete -c tdo -n "__fish_use_subcommand" -a "today tomorrow yesterday next-week last-week monday tuesday wednesday thursday friday saturday sunday" -d "Relative date"

# Note file names
complete -c tdo -n "__fish_use_subcommand" -a "(__tdo_note_files)" -d "Note file"

# Journal entry flags and subcommands
complete -c tdo -n "__fish_seen_subcommand_from e entry" -s f -l find -d "Search journal entries"
complete -c tdo -n "__fish_seen_subcommand_from e entry" -s l -l list -d "List journal entries"
complete -c tdo -n "__fish_seen_subcommand_from e entry" -s m -l message -d "Quick log journal entry"
complete -c tdo -n "__fish_seen_subcommand_from e entry" -a "f find" -d "Search journal entries"
complete -c tdo -n "__fish_seen_subcommand_from e entry" -a "l list" -d "List journal entries"
complete -c tdo -n "__fish_seen_subcommand_from e entry" -a "today tomorrow yesterday next-week last-week monday tuesday wednesday thursday friday saturday sunday" -d "Relative date"
complete -c tdo -n "__fish_seen_subcommand_from e entry" -a "(__tdo_journal_files)" -d "Journal entry"

# Todo command flags
complete -c tdo -n "__fish_seen_subcommand_from t todo" -s m -l message -d "Quickly add todo item"
