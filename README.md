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

<h3>Fast & Simple Note Taking! 📃🚀</h3>

<figure>
  <img src="images/screenshot.jpg" alt="tdo in action">
  <br/>
  <figcaption>tdo in action</figcaption>
</figure>

</div>

tdo is a opinionated, command line based note-taking system. [Demo video](https://youtu.be/N4IRT7M-RLg)

## ✨ Features

- Can help you manage a daily log, todos, journal and notes
- Review pending and upcoming todos, past journal entries and more
- Integrates with git to commit and backup your notes automatically, check [tdo.nvim](https://github.com/2kabhishek/tdo.nvim) for neovim integration
- Has interactive fuzzy searching capabilities powered by fzf
- Can integrate with other tools in pipes and subshells for extended functionality
- Supports all editors, set `$EDITOR` to your choice

## ⚡ Setup

### ⚙️ Requirements

- ripgrep, fzf
- bat (optional, for syntax highlighting in search)
- coreutils (required on macOS, for gdate command)

### 💻 Installation

```bash
git clone https://github.com/2kabhishek/tdo
cd tdo
./install.sh
```

#### 📦 Environment Variables

- `NOTES_DIR` should point to your notes directory
- `TODOS_DIR` optional, should point to your todos directory, default: `NOTES_DIR/todos`
- `JOURNAL_DIR` optional, should point to your journal directory, default: `NOTES_DIR/entries`

- `EDITOR` set to your choice of editor

#### 🐚 Manual Installation

If you want to customize the setup or are facing issues with installation, you can set up tdo manually.

Change these commands according to your needs.

```bash
# Link tdo to a directory that's in PATH (~/.local/bin here)
ln -sfnv "$PWD/tdo.sh" ~/.local/bin/tdo
# Create a notes dir if not already present
mkdir -p $HOME/Projects/Notes
# Add the NOTES_DIR env var to your shell config ~/.bashrc, ~/.zshrc etc
echo "NOTES_DIR=$HOME/Projects/Notes" >> ~/.zshrc
# Add sample templates to your NOTES_DIR
cp -irv templates $NOTES_DIR
# Reload shell config
source ~/.zshrc
```

#### 💾 Git Integration

If you want to sync your notes across devices, you can set up a git repo on the $NOTES_DIR and add GitHub/GitLab as remote.

```bash
cd $NOTES_DIR
git init
git add .
git commit -m 'init: notes'
git remote add origin <your-remote-git-url>
git push origin main
```

tdo will automatically commit every change with a timestamp like `03 Feb 11:33` as commit message.

## 🚀 Usage

If you use Neovim, I highly recommend using [tdo.nvim](https://github.com/2kabhishek/tdo.nvim), it seamlessly integrates `tdo` and `nvim` and adds some useful features on top.

- `tdo` to open today's todos
- `tdo <offset_days>` to open todos from `offset_days` in the past or future, e.g: `tdo 1`, `tdo -2`
- `tdo <note_title>` to open or create a `note_tile.md` note, use folder names to categorise notes, e.g: `tdo tech/vim-tips`
- `tdo note` or `tdo n` to create a new note with the current timestamp in `drafts`
- `tdo entry` or `tdo e` to open today's journal entry
- `tdo entry <offset_days>` to open journal entry from `offset_days` in the past or future, e.g: `tdo e -3`
- `tdo find <text>` or `tdo f` to interactively search for `text` in all your notes
- `tdo find` without any search term to review all your notes
- `tdo todo` or `tdo t` to show all your pending todos
- `tdo commit <path>` or `tdo c` to commit changes in path, happens automatically, needed for plugins and integrations

> Run `tdo h` to get help info on the command line

### 📁 Dir Structure

`tdo` expects an opinionated directory structure to function.

- Notes live in the `notes` sub-dir, use these for long term knowledge management, second brain
- Notes use the [templates/note.md](./templates/note.md) file as template
- Todos live in the `todos` sub-dir, use these for short term notes, daily todos
- Todos use the [templates/todo.md](./templates/todo.md) file as template
- Journal entries live in `entries` sub-dir, use these for personal notes, life logging
- Journal entries use the [templates/entry.md](./templates/entry.md) file as template

```
├── todos
│   └── 2023
│       └── 11
│           └── 2023-11-29.md
├── entries
│   └── 2024
│       └── 02
│           └── 2024-02-03.md
│── notes
│   └── tech
│       └── quit-vim.md
│       └── arch-btw.md
└── templates
    ├── entry.md
    └── note.md
    └── todo.md
```
## Configuration

You can further configure `tdo` by either defining environment variables or via a `tdorc` file.

### Using environment variables

You can set the following (optional) environment variables:

- `ADD_ENTRY_TIMESTAMP` (`["true"|"false"]` defaults to `"true"`): Whether to add a time stamp when using `tdo entry` or `tdo e`.
- `ADD_NEWNOTE_TIMESTAMP` (`["true"|"false"]` defaults to `"false"`): Whether to add a time stamp when creating new notes with `tdo <note_title>`.
- `FILE_NAME_AS_TITLE` (`["true"|"false"]` defaults to `"false"`): Whether to add the file name as title when creating new notes with `tdo <note_title>`. If `"true"`, then it adds `<note_title>` as a markdown title in the first line of the new note.
- `ENTRY_TIMESTAMP_FORMAT` (`[string]` defaults to `"## %a, %I:%M %p"` or `"## Mon, 12:00 PM"`): can be any bash string such as a date format expression. It is ignored if `ADD_ENTRY_TIMESTAMP` is set to `"false"`.
- `NOTE_TIMESTAMP_FORMAT`(`[string]` defaults to `"## %a. %b %d, %Y - %I:%M %p"` or `"## Fri. Apr 06, 2024 - 06:48 PM"`): can be any bash string such as a date format expression. It is ignored if `ADD_NEWNOTE_TIMESTAMP` is set to `"false"`.

### Using a `tdorc` file

Alternatively, it is possible to define the same variables in a `$HOME/.config/tdorc` file following bash syntax. For example:

```bash
ADD_ENTRY_TIMESTAMP=false
ADD_NEWNOTE_TIMESTAMP=true
FILE_NAME_AS_TITLE=true
ENTRY_TIMESTAMP_FORMAT="## %I:%M %p"
NOTE_TIMESTAMP_FORMAT="## Created: %a. %b %d, %Y at %I:%M %p"
```

**Note** that variables defined in `tdorc` will override the corresponding environment variables.

## 🏗️ What's Next

You tell me!

## 🧑‍💻 Behind The Code

### 🌈 Inspiration

After trying out every note management system under the sun I had decided on using plain markdown notes [powered by nvim2k](https://youtu.be/FP7sQhc8kek).

tdo is a spiritual successor and complimentary tool to that, taking the same principles and making it more accessible and simple.

### 🔍 More CLI Tools

- [cmtr](https://github.com/2kabhishek/cmtr) — Fast git commits
- [mkrepo](https://github.com/2kabhishek/mkrepo) — Spin up new GitHub repos from the CLI
- [ghpm](https://github.com/2kabhishek/ghpm) — Manage all your GitHub repos
- [gsync](https://github.com/2kabhishek/gsync) — Sync your git repos

### 🧰 Tooling

- [dots2k](https://github.com/2kabhishek/dots2k) — Dev Environment
- [nvim2k](https://github.com/2kabhishek/nvim2k) — Personalized Editor
- [sway2k](https://github.com/2kabhishek/sway2k) — Desktop Environment
- [qute2k](https://github.com/2kabhishek/qute2k) — Personalized Browser

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
