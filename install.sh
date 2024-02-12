#!/bin/bash
# shellcheck disable=2016

if [ -z "$EDITOR" ]; then
    echo "Error: EDITOR environment variable not set. Please set it to your preferred text editor."
    exit 1
fi

case "$SHELL" in
*/bash) exports_file="$HOME/.bashrc" ;;
*/zsh) exports_file="$HOME/.zshrc" ;;
*/fish) exports_file="$HOME/.config/fish/config.fish" ;;
*) echo "Unsupported shell. Please set the environment variables manually." && exit 1 ;;
esac

mkdir -p ~/.local/bin
ln -sfnv "$PWD/tdo.sh" ~/.local/bin/tdo

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$exports_file"
fi

if [ ! -d "$NOTES_DIR" ]; then
    NOTES_DIR="$HOME/Projects/notes"
    mkdir -p "$NOTES_DIR"
    echo "export NOTES_DIR=$NOTES_DIR" >>"$exports_file"
fi

cp -irv templates/ "$NOTES_DIR"

echo "tdo setup completed successfully!"
echo "Please make sure to reload your shell configuration using 'source $exports_file'."
