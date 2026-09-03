#!/usr/bin/env bash
set -e

current_dir="${BASH_SOURCE[0]%/*}"
[[ "$current_dir" == "${BASH_SOURCE[0]}" || "$current_dir" == "." ]] && current_dir="$PWD"

for cmd in git rg fzf; do
    command -v "$cmd" &>/dev/null || echo "Warning: '$cmd' is not installed."
done

NOTES_DIR="${NOTES_DIR:-$HOME/Projects/notes}"
mkdir -p "$NOTES_DIR/templates"
if [[ -d "$current_dir/templates" ]]; then
    for tpl in "$current_dir/templates/"*; do
        if [[ -f "$tpl" ]]; then
            tpl_name="${tpl##*/}"
            [[ ! -f "$NOTES_DIR/templates/$tpl_name" ]] && cp "$tpl" "$NOTES_DIR/templates/$tpl_name"
        fi
    done
fi

mkdir -p "$HOME/.local/bin"
ln -sfnv "$current_dir/tdo.sh" "$HOME/.local/bin/tdo"

echo "tdo setup completed successfully!"
