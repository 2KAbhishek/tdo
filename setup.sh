#!/usr/bin/env bash
# shellcheck disable=2016
set -e

current_dir="${BASH_SOURCE[0]%/*}"
[[ "$current_dir" == "${BASH_SOURCE[0]}" || "$current_dir" == "." ]] && current_dir="$PWD"
readonly current_dir

NOTES_DIR="${NOTES_DIR:-$HOME/Projects/notes}"
EDITOR="${EDITOR:-${VISUAL:-nvim}}"

install_fish() {
    if command -v fish &>/dev/null; then
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            fish -c "fish_add_path $HOME/.local/bin" 2>/dev/null || true
        fi
        if ! printenv NOTES_DIR > /dev/null 2>&1; then
            fish -c "set -Ux NOTES_DIR $NOTES_DIR" 2>/dev/null || true
        fi
    fi
}

install_shell() {
    local exports_file="$1"
    mkdir -p "$(dirname "$exports_file")"
    touch "$exports_file"

    if ! grep -Fq '$HOME/.local/bin' "$exports_file"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$exports_file"
    fi
    if ! grep -Fq 'NOTES_DIR=' "$exports_file"; then
        echo "export NOTES_DIR=\"$NOTES_DIR\"" >> "$exports_file"
    fi
}

echo "Setting up tdo..."
mkdir -p "$NOTES_DIR"
if [ -d "$current_dir/templates" ]; then
    mkdir -p "$NOTES_DIR/templates"
    cp -rn "$current_dir/templates/"* "$NOTES_DIR/templates/" 2>/dev/null || true
fi

mkdir -p "$HOME/.local/bin"
ln -sfnv "$current_dir/tdo.sh" "$HOME/.local/bin/tdo"

current_shell="${SHELL:-/bin/bash}"
case "$current_shell" in
    */bash) install_shell "$HOME/.bashrc" ;;
    */zsh)  install_shell "$HOME/.zshrc" ;;
    */fish) install_fish ;;
    *)      install_shell "$HOME/.profile" ;;
esac

echo "tdo setup completed successfully!"
