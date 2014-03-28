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
* Autocompletion support with `<C-x><C-o>` (omnicomplete)
* Integrated and improved snippets support 
* Better gofmt on save, keeps cursor position and doesn't break your undo
  history
* Go to symbol/declaration
* Automatically import packages
* Compile and build package
* Run quickly your snippet
* Run tests and see any errors in quick window
* Lint your code
* Advanced source analysis tool with oracle

## Install

If you use pathogen, just clone it into your bundle directory:

```bash
$ cd ~/.vim/bundle
$ git clone https://github.com/fatih/vim-go.git
```

### Optional

Autocompletion is enabled by default via `<C-x><C-o>`, to get real-time
completion (completion by type) install YCM:

```bash
$ cd ~/.vim/bundle
$ git clone https://github.com/Valloric/YouCompleteMe.git
$ cd YouCompleteMe
$ ./install.sh
```

Snippets and integration with YCM is already done. Just install UltiSnips:

```bash
$ cd ~/.vim/bundle
$ git clone https://github.com/SirVer/ultisnips.git
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

Fmt your file explicitly

	:Fmt

Run quickly go run on your current main package

	:Gorun

Go to a declaration under your cursor or give an identifier

	:Godef
	:Godef <identifier>

Run go test in current directory, any errors will be populate in quickfix window

	:Gotest

Build your package, it doesn't create any output binary, however it outputs any
errors (if ann) in quickfix window

	:make

Show .go source files for the current package

	:Gofiles

Show dependencies for the current package

	:Godeps

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

Change individual binary paths, if the binary doesn't exist vim-go will 
download and install it to `g:go_bin_path`

```vim
let g:go_gocode_bin="~/your/custom/gocode/path"
let g:go_goimports_bin="~/your/custom/goimports/path"
let g:go_godef_bin="~/your/custom/godef/path"
let g:go_oracle_bin="~/your/custom/godef/path"
let g:go_lint_bin="~/your/custom/lint/path"
```

If you wish you can disable auto installation of binaries completely.

```vim
let g:go_disable_autoinstall = 1
```

## Why another plugin?

This plugin/package is born mainly by frustrating. I had to re-install my Vim
plugins and especially for Go I had to install a lot of seperate different
plugins, setup the necessary binaries to make them work together and hope not
to lose them again. Also lot's of the plugins lacks of proper settings. This
plugin is improved in every way and is used by me for months. Use it and give
it a try. I hope you like it. If not, feel free to contribute to the project.

## Credits

* Go Authors for offical vim plugins
* Gocode, Godef, Golint, Oracle, Goimports projects
* Other vim-plugins, thanks for inspiration (vim-golang, go.vim, vim-gocode, vim-godef)
