# vim-go

**WIP, use with cautious until it's released**

An attempt to bring full featured Go support to Vim. This is a single pathogen
package to be easily installed. Do not use it with any other vim go plugin.

vim-go is different, you just drop it and everything else works. Most of the
plugins are improved for a better experience. No need to install binaries,
configure plugins, add additional dependencies. etc.. vim-go installs
automatically all necessary binaries if they are not found. It comes with
pre-defined sensible settings (like auto fmt on save).

## Features

* Syntax highlighting
* Auto go fmt on save
* Go to symbol/declaration
* Automatically import packages
* Autocomplete with `<C-x><C-o>` (omnicomplete)
* Compile and build package
* Lint your code
* Advanced source analysis tool with oracle

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

## Usage

Import a package

	:Import <path>

Import a package with custom local name

	:ImportAs <localname> <path>

Drop a package

	:Drop <path>

Lint your current file

	:Lint

Open relevant Godoc under your cursor or give package name

	:Godoc
	:Godoc <identifier>

Fmt your file

	:Fmt

Go to a declaration under your cursor or give an identifier

	:Godef
	:Godef <identifier>

Build your package

	:make

## Settings

Disable auto go fmt on save

```vim
let g:go_fmt_autosave = 0
```

Disable goimports and use gofmt instead of

```vim
let g:go_fmt_command = "gofmt"
```

By default binaries are installed to `$HOME/.vim-go/`. To change it:

```vim
let g:go_bin_path = expand("~/.mypath")
let g:go_bin_path = "/home/fatih/.mypath"      "or give relative path
```

Change individual binary paths, this also disables automatic installing for the given package.

```vim
let g:go_gocode_bin="~/your/custom/gocode/path"
let g:go_goimports_bin="~/your/custom/goimports/path"
let g:go_godef_bin="~/your/custom/godef/path"
let g:go_oracle_bin="~/your/custom/godef/path"
let g:go_lint_bin="~/your/custom/lint/path"
```

## Why another plugin ?

This plugin/package is born mainly by frustrating. I had to re-install my Vim
plugins and especially for Go I had to install a lot of seperate different
plugins, setup the necessary binaries to make them work together and hope not
to lose them again. Also lot's of the plugins lacks of proper settings. This
plugin is improved in every way and is used by me for months. Use it and decide
your self.

## Credits

* Go Authors for offical vim plugins
* Gocode, Godef, Golint, Oracle, Goimports projects
* Other vim-plugins, thanks for inspiration (vim-golang, go.vim, vim-gocode, vim-godef)
