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

setup_completions() {
    local completion_script="$current_dir/completions/tdo_completion.sh"
    local source_cmd="[ -f \"$completion_script\" ] && source \"$completion_script\""

    # Fish completion: native autoloading via symlink
    if command -v fish &>/dev/null || [[ -d "$HOME/.config/fish" ]]; then
        mkdir -p "$HOME/.config/fish/completions"
        ln -sfnv "$current_dir/completions/tdo_completion.fish" "$HOME/.config/fish/completions/tdo.fish"
    fi

    # Check if already configured in any common shell rc file
    local rc
    for rc in "$HOME/.config/shell/local.sh" "${ZDOTDIR:-$HOME}/.zshrc" "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$rc" ]] && grep -qs "tdo_completion" "$rc"; then
            echo "tdo completion already configured in $rc"
            return 0
        fi
    done

    # Determine best target file
    local target_rc=""
    if [[ -f "$HOME/.config/shell/local.sh" ]]; then
        target_rc="$HOME/.config/shell/local.sh"
    elif [[ "$SHELL" == *"zsh"* && -f "${ZDOTDIR:-$HOME}/.zshrc" ]]; then
        target_rc="${ZDOTDIR:-$HOME}/.zshrc"
    elif [[ "$SHELL" == *"bash"* && -f "$HOME/.bashrc" ]]; then
        target_rc="$HOME/.bashrc"
    elif [[ -f "$HOME/.zshrc" ]]; then
        target_rc="$HOME/.zshrc"
    fi

    if [[ -n "$target_rc" ]]; then
        printf "\n# tdo completion\n%s\n" "$source_cmd" >> "$target_rc"
        echo "Added tdo completion to $target_rc"
    else
        echo "Tip: Add the following line to your shell rc file for completion:"
        echo "  $source_cmd"
    fi
}

setup_completions

echo "tdo setup completed successfully!"
