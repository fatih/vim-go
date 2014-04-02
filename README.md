# vim-go

Full featured Go development environment support for Vim. vim-go installs
automatically all necessary binaries if they are not found. It comes with
pre-defined sensible settings (like auto gofmt on save), has autocomplete,
snippet support, go toolchain commands, etc... Do not use it with other Go
plugins.


## Features

* Improved Syntax highlighting
* Auto completion support
* Integrated and improved snippets support
* Better gofmt on save, keeps cursor position and doesn't break your undo
  history
* Go to symbol/declaration
* Automatically import packages
* Compile and build package
* Run quickly your snippet
* Run tests and see any errors in quickfix window
* Lint your code
* Advanced source analysis tool with oracle
* Checking for unchecked errors.

## Install


If you use pathogen, just clone it into your bundle directory:

```bash
$ cd ~/.vim/bundle
$ git clone https://github.com/fatih/vim-go.git
```

For the first Vim start it will try to download and install all necessary go
binaries. To disable this behaviour please check out
[settings](#settings).

Autocompletion is enabled by default via `<C-x><C-o>`, to get real-time
completion (completion by type) install YCM:

```bash
$ cd ~/.vim/bundle
$ git clone --recursive https://github.com/Valloric/YouCompleteMe.git
$ cd YouCompleteMe
$ ./install.sh
```

## Usage

All [features](#features) are enabled by default. There is no additional
settings needed.  Usage and commands are listed in `doc/vim-go.txt`. Just open
the help page to see all commands:

	:help vim-go

Current commands:

```vimrc
:GoImport <path>
:GoImportAs <localname> <path>
:GoDrop <path>
:GoDisableGoimports
:GoEnableGoimports
:GoLint
:GoDoc <identifier>
:GoFmt
:GoDef <identifier>
:GoRun <expand>
:GoBuild
:GoTest
:GoErrCheck
:GoFiles
:GoDeps
:GoUpdateBinaries
:GoOracleDescribe
:GoOracleCallees
:GoOracleCallers
:GoOracleCallgraph
:GoOracleImplements
:GoOracleChannelPeers
```

## Settings
Below are some settings for `.vimrc` you might find useful :

Import the package under your cursor with `<leader>i`

```vim
au Filetype go nnoremap <buffer> <leader>i :exe 'GoImport ' . expand('<cword>')<CR>
```

Run `go run` for the current file with `<leader>r`

```vim
au Filetype go nnoremap <leader>r :GoRun %<CR>
```

Open a vertical, horizontal or a new tab and go to defintion/declaration of the
identified under your cursor:

```vim
au Filetype go nnoremap <leader>v :vsp <CR>:exe "GoDef" <CR>
au Filetype go nnoremap <leader>s :sp <CR>:exe "GoDef"<CR>
au Filetype go nnoremap <leader>t :tab split <CR>:exe "GoDef"<CR>
```

By default vim-go shows errors for the fmt command, you can disable it:

```vim
let g:go_fmt_fail_silently = 1
```

Disable auto fmt on save

```vim
let g:go_fmt_autosave = 0
```

Disable goimports and use gofmt for the fmt command:

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
let g:go_golint_bin="~/your/custom/golint/path"
let g:go_errcheck_bin="~/your/custom/errcheck/path"
```

If you wish you can disable auto installation of binaries completely.

```vim
let g:go_disable_autoinstall = 1
```

## Snippets

Snippets are useful and very powerful. Vim-go has a sensible integration with
[ultisnips](https://github.com/SirVer/ultisnips) and
[neosnippet](https://github.com/Shougo/neosnippet.vim). By default ultisnips is
used, however you can change it to neosnippet with:

```vim
let g:go_snippet_engine = "neosnippet"
```

Snippet feature is enabled only if the snippet plugin are installed.  Below are
some examples snippets and the correspondings trigger keywords, The `|`
character defines the cursor. Ultisnips has suppport for multiple cursors


`ff` is useful for debugging:

```go
fmt.Printf(" | %+v\n", |)
```

`errn` expands to:

```go
if err != nil {
	return err
}
```

Use `gof` to quickly create a anonymous goroutine :

```go
go func() {
	|
}()
```

To add `json` tags to a struct field, use `json` trigger:

```
type foo struct {
	bar string  `json:"myField"
		   ^ type `json` here, hit tab and type "myField". It will expand to `json:"myField"`
}
```

...

And many more! For the full list have a look at the
[included snippets](https://github.com/fatih/vim-go/blob/master/gosnippets/):



## Why another plugin?

This plugin/package is born mainly by frustrating. I had to re-install my Vim
plugins and especially for Go I had to install a lot of seperate different
plugins, setup the necessary binaries to make them work together and hope not
to lose them again. Lot's of the plugins out there lacks of proper settings.
This plugin is improved and contains all my fixes/changes that I'm using for
months under heavy go development environment.

Give it a try. I hope you like it. Feel free to contribute to the project.

## Credits

* Go Authors for offical vim plugins
* Gocode, Godef, Golint, Oracle, Goimports, Errcheck projects and authors of those projects.
* Other vim-plugins, thanks for inspiration (vim-golang, go.vim, vim-gocode, vim-godef)
