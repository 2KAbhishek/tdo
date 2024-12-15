#!/usr/bin/env bash
# shellcheck disable=2016

install_fish() {
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        fish -c "fish_add_path $HOME/.local/bin"
    fi
    if ! printenv NOTES_DIR > /dev/null; then
        fish -c "set -Ux NOTES_DIR $NOTES_DIR"
    fi
}

install_shell() {
    exports_file="$1"
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$exports_file"
    fi
    if ! printenv NOTES_DIR > /dev/null; then
        echo "export NOTES_DIR=$NOTES_DIR" >>"$exports_file"
    fi
}

if [ -z "$EDITOR" ]; then
    echo "Error: EDITOR environment variable not set. Please set it to your preferred text editor."
    exit 1
fi

if [ ! -d "$NOTES_DIR" ]; then
    NOTES_DIR="$HOME/Projects/notes"
    mkdir -p "$NOTES_DIR"
fi
cp -irv templates "$NOTES_DIR/"
mkdir -p ~/.local/bin
ln -sfnv "$PWD/tdo.sh" ~/.local/bin/tdo

case "$SHELL" in
*/bash) install_shell "$HOME/.bashrc" ;;
*/zsh) install_shell "$HOME/.zshrc" ;;
*/fish) install_fish ;;
*) echo "Unsupported shell. Please set the environment variables manually." && exit 1 ;;
esac

echo "tdo setup completed successfully!"
echo "Please make sure to reload your shell"
