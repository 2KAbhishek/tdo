<div align = "center">

<h1><a href="https://github.com/2kabhishek/tdo">tdo</a></h1>

<a href="https://github.com/2KAbhishek/tdo/blob/main/LICENSE">
<img alt="License" src="https://img.shields.io/github/license/2kabhishek/tdo?style=flat&color=eee&label="> </a>

<a href="https://github.com/2KAbhishek/tdo/graphs/contributors">
<img alt="People" src="https://img.shields.io/github/contributors/2kabhishek/tdo?style=flat&color=ffaaf2&label=People"> </a>

<a href="https://github.com/2KAbhishek/tdo/stargazers">
<img alt="Stars" src="https://img.shields.io/github/stars/2kabhishek/tdo?style=flat&color=98c379&label=Stars"></a>

<a href="https://github.com/2KAbhishek/tdo/network/members">
<img alt="Forks" src="https://img.shields.io/github/forks/2kabhishek/tdo?style=flat&color=66a8e0&label=Forks"> </a>

<a href="https://github.com/2KAbhishek/tdo/watchers">
<img alt="Watches" src="https://img.shields.io/github/watchers/2kabhishek/tdo?style=flat&color=f5d08b&label=Watches"> </a>

<a href="https://github.com/2KAbhishek/tdo/pulse">
<img alt="Last Updated" src="https://img.shields.io/github/last-commit/2kabhishek/tdo?style=flat&color=e06c75&label="> </a>

<h3>Todos and Notes, Blazingly Fast! 📃🚀</h3>

<figure>
  <img src="images/screenshot.jpg" alt="tdo in action">
  <br/>
  <figcaption>tdo in action</figcaption>
</figure>

</div>

tdo is a opinionated, command line based note-taking system.

## ✨ Features

- Can help you manage a daily log, todos, journal and notes
- Quickly review pending and upcoming todos, past journal entries and more
- Has interactive fuzzy searching capabilities powered by fzf
- Blazingly fast, thanks to ripgrep
- Integrates with git to commit and backup your notes automatically
- Can integrate with other tools in pipes and subshells for extended functionality

## ⚡ Setup

### ⚙️ Requirements

- ripgrep, fzf
- bat (optional, for syntax highlighting in search)

#### 📦 Environment Variables

- `NOTES_DIR` should point to your notes directory
- `TODO_DIR` optional, should point to your todos directory, default: `NOTES_DIR/todos`
- `JOURNAL_DIR` optional, should point to your journal directory, default: `NOTES_DIR/entries`

- `EDITOR` set to your choice of editor

### 💻 Installation

```bash
git clone https://github.com/2kabhishek/tdo
cd tdo
# Link tdo to a directory that's in PATH (~/.local/bin here)
ln -sfnv "$PWD/tdo.sh" ~/.local/bin/tdo
# Create a notes dir if not already present
mkdir -p ~/Projects/notes
# Add the NOTES_DIR env var to your shell config (~/.bashrc | ~/.zshrc | ~/.profile)
echo "NOTES_DIR=~/Projects/notes" >> ~/.profile
```

## 🚀 Usage

```bash
tdo: Todos and Notes, Blazingly Fast! 📃🚀

Usage: tdo [command | note_path | offset]

Commands:
-e | --entry  | e | entry   creates a new journal entry, accepts offset
-f | --find   | f | find    searches for argument term in notes
-n | --note   | n | note    creates a new note with title from user prompt
                            uses current time if no title is provided
-s | --search | s | search  same as find
-t | --todo   | t | todo    shows all pending todos
-h | --help   | h | help    shows this help message

Example:
# open today's todo
tdo
# open tommorow's todo
tdo 1
# open or create the note tech/vim.md
tdo tech/vim
# open today's journal entry
tdo e
# open day before yesterday's journal entry
tdo e -2
# search for neovim in all notes
tdo f neovim
# review all notes
tdo f
# show all pending todos
tdo t

```

The look and feel of the fzf window can be configured using env variables, check [fzf docs](https://github.com/junegunn/fzf#environment-variables) for more.

### 📁 Dir Structure

`tdo` expects an opinionated directory structure to function.

- Notes are kept in the `notes` dir, these are used for long term storage, second brain
- Notes use the `templates/note.md` file as template
- Todos are kept in `todos` dir, these can used for short term notes, daily todos
- Todos use the `templates/todo.md` file as template
- Journal entries are kept in `entries` dir, these are used for personal notes, life logging
- Journal entries use the `templates/entry.md` file as template

```
├── todos
│   └── 2023
│       └── 11
│           ├── 2023-11-28.md
│           └── 2023-11-29.md
├── entries
│   └── 2024
│       └── 02
│           ├── 2024-02-02.md
│           └── 2024-02-03.md
└── notes
    ├── tech
    │   └── quit-vim.md
    │   └── arch-btw.md
    └── templates
        ├── note.md
        └── todo.md
```

### 💾 Git Integration

If any of your notes directory is under git, tdo will automatically commit and push every change with a timestamp like `03 Feb 11:33` as commit message.

## 🏗️ What's Next

You tell me!

## 🧑‍💻 Behind The Code

### 🌈 Inspiration

After trying out every note management system under the sun I had decided on using plain markdown notes [powered by nvim2k](https://youtu.be/FP7sQhc8kek).

tdo is a spiritual successor and complimentary tool to that, taking the same principles and making it more accessible.

### 🧰 Tooling

- [dots2k](https://github.com/2kabhishek/dots2k) — Dev Environment
- [nvim2k](https://github.com/2kabhishek/nvim2k) — Personalized Editor
- [sway2k](https://github.com/2kabhishek/sway2k) — Desktop Environment
- [qute2k](https://github.com/2kabhishek/qute2k) — Personalized Browser

### 🔍 More Info

- [cmtr](https://github.com/2kabhishek/cmtr) — Easily commit and backup your notes

<hr>

<div align="center">

<strong>⭐ hit the star button if you found this useful ⭐</strong><br>

<a href="https://github.com/2KAbhishek/tdo">Source</a>
| <a href="https://2kabhishek.github.io/blog" target="_blank">Blog </a>
| <a href="https://twitter.com/2kabhishek" target="_blank">Twitter </a>
| <a href="https://linkedin.com/in/2kabhishek" target="_blank">LinkedIn </a>
| <a href="https://2kabhishek.github.io/links" target="_blank">More Links </a>
| <a href="https://2kabhishek.github.io/projects" target="_blank">Other Projects </a>

</div>
