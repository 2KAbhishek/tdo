# TDO Fish Tab Completions

function __tdo_complete
    find $NOTES_DIR -mindepth 1 -not -path '*/\.*' | sed "s|^$NOTES_DIR/||" | sort
end

complete -c tdo -f -a "(__tdo_complete)"

