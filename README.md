# go.vim

An attempt to bring full featured Go support to Vim. All necessary
binaries(gocode, goimports, godef, etc..) are installed once at startup
automatically. Open an issue for bugs/improvements.

## Features

* Syntax highlighting
* Auto go fmt on save
* Go to symbol/declaration with godef
* Automatically import packages with goimports
* Autocomplete with `<C-x><C-o>` (gocode omnicomplete)

## Install

If you use pathogen, just clone it into your bundle directory:

```bash
$ cd ~/.vim/bundle
$ git clone git://github.com/fatih/go.vim.git
```

Autocompletion is enabled by default via `<C-x><C-o>`, to get real-time
completion (completion by type) install YCM:

```bash
$ cd ~/.vim/bundle
$ git clone git@github.com:Valloric/YouCompleteMe.git
$ cd YouCompleteMe
$ ./install.sh
```

## Customize

Disable auto go fmt on save

    let g:go_fmt_autosave = 0

Disable goimports

    let g:gofmt_command = "gofmt"

Change binary paths. It also disables automatic installing.

    let g:gocode_bin="~/your/custom/gocode/path"
    let g:goimports_bin="~/your/custom/goimports/path"
    let g:godef_bin="~/your/custom/godef/path"
    let g:oracle_bin="~/your/custom/godef/path"
