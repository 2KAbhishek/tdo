# TDO Fish Tab Completions

function __tdo_complete
    set -l notes_dir "$NOTES_DIR"
    test -d "$NOTES_DIR/notes"; and set notes_dir "$NOTES_DIR/notes"
    find "$notes_dir" -type f -name '*.md' -not -path '*/.*' | sed 's|.*/||' | sort -u
end

complete -c tdo -f -a "(__tdo_complete)"
