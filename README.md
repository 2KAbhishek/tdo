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
- Has interactive fuzzy searching capabilities powered by fzf
- Blazingly fast, thanks to ripgrep
- Integrates with git to commit and backup your notes automatically

## ⚡ Setup

### ⚙️ Requirements

- ripgrep, fzf
- bat (optional, for syntax highlighting in search)

- `NOTES_DIR` env variable pointing to your notes directory
- `JOURNAL_DIR` env variable pointing to your journal directory (optional, if you want to have a separate journal)
- `EDITOR` env variable set to your choice of editor

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
Usage: tdo [options] [arguments]

Options:
-e | --entry | e | entry:    searches for argument in notes
-f | --find  | f | find:     searches for argument in notes
-t | --todo  | t | todo:     shows all pending todos
-h | --help  | h | help:     shows this help message

Example:
# opens today's todo file
tdo
# opens the note for vim in tech dir
tdo tech/vim
# shows all pending todos
tdo t
# make a new entry
tdo e
# searches for neovim in all notes
tdo f neovim
# review all notes
tdo f
```

The look and feel of the fzf window can be configured using env variables, check [fzf docs](https://github.com/junegunn/fzf#environment-variables) for more.

### 📁 Dir Structure

`tdo` expects a certain directory structure to function.

#### 📓 Notes

- Todos are kept in `log` dir, these can also be used for short term notes
- Todos use the `notes/templates/todo.md` file as template
- Long term notes are to be categorized under the `notes` dir
- Notes use the `notes/templates/note.md` file as template

```
├── log
│   └── 2023
│       └── 11
│           ├── 2023-11-28.md
│           └── 2023-11-29.md
└── notes
    ├── tech
    │   └── quit-vim.md
    │   └── arch-btw.md
    └── templates
        ├── note.md
        └── todo.md
```

#### ✍️ Journal

For journal entries we have a simpler directory structure.

- Entries are placed in year/month/day md files
- Template path is `$ENTYR_DIR/template.md`

```
├── 2023
│   ├── 10
│   ├── 11
│   └── 12
│       ├── 2023-12-12.md
│       ├── 2023-12-13.md
│       └── 2023-12-15.md
└── template.md
```

### 💾 Git Integration

If either of your `$NOTES_DIR` or `$JOURNAL_DIR` is under git, tdo will automatically commit and push every change with the timestamp like `Fri, 15 Dec 23, 10:53 AM` as commit message.

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
