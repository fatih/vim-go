# vim-go

Full featured Go development environment support for Vim. vim-go installs
automatically all necessary binaries if they are not found. It comes with
pre-defined sensible settings (like auto gofmt on save), has autocomplete,
snippet support, improved syntax highlighting, go toolchain commands, etc... 
Do not use it with other Go plugins.

![vim-go](https://dl.dropboxusercontent.com/u/174404/vim-go.png)

## Features

* Improved Syntax highlighting, such as Functions, Operators, Methods..
* Auto completion support via `gocode`
* Better `gofmt` on save, keeps cursor position and doesn't break your undo
  history
* Go to symbol/declaration with `godef`
* Look up documentation with `godoc` inside Vim or open it in browser.
* Automatically import packages via `goimports`
* Compile and `go build` your package, install it with `go install`
* `go run` quickly your current file/files
* Run `go test` and see any errors in quickfix window
* Lint your code with `golint`
* Run your code trough `go vet` to catch static errors.
* Advanced source analysis tool with `oracle`
* List all source files and dependencies
* Checking with `errcheck` for unchecked errors.
* Integrated and improved snippets. Supports `ultisnips` or `neosnippet`
* Share your current code to [play.golang.org](http://play.golang.org)
* On-the-fly type information about the word under the cursor
* Tagbar support to show tags of the source code in a sidebar with `gotags` 

## Install


If you use pathogen, just clone it into your bundle directory:

```bash
$ cd ~/.vim/bundle
$ git clone https://github.com/fatih/vim-go.git
```

For Vundle add this line to your vimrc:

```vimrc
Plugin 'fatih/vim-go'
```
and execute `:PluginInstall`


For the first Vim start it will try to download and install all necessary go
binaries. To disable this behaviour please check out
[settings](#settings).

Autocompletion is enabled by default via `<C-x><C-o>`, to get real-time
completion (completion by type) install:
[YCM](https://github.com/Valloric/YouCompleteMe) or
[neocomplete](https://github.com/Shougo/neocomplete.vim)

To get displayed source code tag informations on a sidebar install
[tagbar](https://github.com/majutsushi/tagbar).

## Usage

All [features](#features) are enabled by default. There are no additional
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
:GoDocBrowser <identifier>
:GoFmt
:GoVet
:GoDef <identifier>
:GoRun <expand>
:GoBuild
:GoInstall
:GoPlay
:GoInfo
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

## Mappings

vim-go has several `<Plug>` mappings which can be used to create custom
mappings. Below are some examples you might find useful:

Show type info for the word under your cursor with `<leader>i` (useful if you
have disabled auto showing type info via `g:go_auto_type_info`)

```vim
au FileType go nmap <Leader>i <Plug>(go-info)
```

Open the relevant Godoc for the word under the cursor with `<leader>gd` or open
it vertically with `<leader>gv`

```vim
au FileType go nmap <Leader>gd <Plug>(go-doc)
au FileType go nmap <Leader>gv <Plug>(go-doc-vertical)
```

Run commands, such as  `go run` with `<leader>r` for the current file or `go build` and `go test` for
the current package with `<leader>b` and `<leader>t`.

```vim
au FileType go nmap <leader>r <Plug>(go-run)
au FileType go nmap <leader>b <Plug>(go-build)
au FileType go nmap <leader>t <Plug>(go-test)
```

Replace `gd` (Goto Declaration) for the word under your cursor (replaces current buffer):

```vim
au FileType go nmap gd <Plug>(go-def)
```

Or open the defitinion/declaration in a new vertical, horizontal or tab for the
word under your cursor:

```vim
au FileType go nmap <Leader>ds <Plug>(go-def-split)
au FileType go nmap <Leader>dv <Plug>(go-def-vertical)
au FileType go nmap <Leader>dt <Plug>(go-def-tab)
```

More `<Plug>` mappings can be seen with `:he go-mappings`. Also these are just
recommendations, you are free to create more advanced mappings or functions
based on `:he go-commands`.

## Settings
Below are some settings you might find useful. For the full list see `:he go-settings`.

Disable opening browser after posting to your snippet to `play.golang.org`:

```vim
let g:go_play_open_browser = 0
```

By default vim-go shows errors for the fmt command, to disable it:

```vim
let g:go_fmt_fail_silently = 1
```

Disable auto fmt on save:

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
let g:go_bin_path = "/home/fatih/.mypath"      "or give absolute path
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

Snippet feature is enabled only if the snippet plugins are installed.  Below are
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

This plugin/package is born mainly from frustration. I had to re-install my Vim
plugins and especially for Go I had to install a lot of seperate different
plugins, setup the necessary binaries to make them work together and hope not
to lose them again. Lot's of the plugins out there lacks of proper settings.
This plugin is improved and contains all my fixes/changes that I'm using for
months under heavy go development environment.

Give it a try. I hope you like it. Feel free to contribute to the project.

## Credits

* Go Authors for offical vim plugins
* Gocode, Godef, Golint, Oracle, Goimports, Gotags, Errcheck projects and authors of those projects.
* Other vim-plugins, thanks for inspiration (vim-golang, go.vim, vim-gocode, vim-godef)

