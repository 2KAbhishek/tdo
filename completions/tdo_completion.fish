# TDO Fish Tab Completions

function __tdo_complete
    find "$NOTES_DIR" -type f -not -path '*/\.*' | sed "s|^$NOTES_DIR/||" | sort
end

complete -c tdo -f -a "(__tdo_complete)"

