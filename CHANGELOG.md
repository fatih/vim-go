## 1.7 (unreleased)

IMPROVEMENTS:

* Enable passing the `-tags` flag to `:GoDef`. Now you can pass build tags to `:GoDef` via `:GoGuruTags` or `g:go_guru_tags`
* Internal refactoring to use custom `system()` function that wraps both the standard `system()` call and `vimproc`. Now all system calls will take advantage and will use `vimproc` if installed. [gh-801]
* Add new `http.HandlerFunc` snippets with `hf` and `hhf` shortcuts [gh-816]

BUG FIXES:
* Fix `:GoCoverage` accidently enabling syntax highlighting for users who don't use syntax (i.e syntax off) [gh-827]
* Fix commenting out block of texts for Go templates (filetype gothtmltmpl) [gh-813]
* Fix `:GoImplements` failing because of an empty scope definition. Now we default to current package to make it usable.


## 1.6 (April 25, 2016)

FEATURES:

* New `CHANGELOG.md` file (which you're reading now). This will make it easier
  for me to track changes and release versions
* **`:GoCoverage`** is now highlighting the current source file for
  covered/uncovered lines. If called again it runs the tests and updates the
  annotation. Use `:GoCoverageClear` to clear the coverage annotation.
  This is a pretty good addition to vim-go and I suggest to check out the gif
  that shows it in action: https://twitter.com/fatih/status/716722650383564800
  [gh-786]
* **`:GoCoverageToggle`** just like `:GoCoverage` but acts as a toggle. If run
  again it clears the annotation.
* **`:GoCoverageBrowser`** opens a new annotated HTML page. This is the old
  `:GoCoverage` behavior [gh-786]
* **`:GoDoc`** uses now [gogetdoc](https://github.com/zmb3/gogetdoc) to
  lookup and display the comment documentation for the identifier under the
  cursor. This is more superior as it support looking up dot imports, named
  imports and imports where package name and file name are different [gh-782]
* **`guru support`**: `oracle` is replaced by the new tool `guru`. `oracle.vim`
  is therefore renamed to `guru.vim`. I've also refactored the code to make it
  much more easier to maintain and add additional features in future (such as
  upcoming JSON decoding). vim-go is now fully compatible with `guru`. Please
  be sure you have installed `guru`. You can easily do it with
  `:GoInstallBinaries`.
* **`:GoDef`** uses now `guru definition` under the hood instead of `godef`.
  This fixes the following issues: 1. dot imports 2. vendor imports 3. folder
  != package name imports. The tool `godef` is also deprecated and not used
  anymore.
* **`:GoDef`** does have now history of the call stack. This means you can
  easily jump back to your last entry. This can be done with the new command
  `:GoDefPop` or the mapping `CTRL-t`. To see the stack and jump between entries
  you can use the new command `:GoDefStack`, which shows the list of all stack
  entries. To reset the stack list anytime you can call `:GoDefStackClear`
  [gh-776]

IMPROVEMENTS:

* **`:GoCoverage`** is executed asynchronously when used within Neovim [gh-686]
* **`:GoTestFunc`** supports now testable examples [gh-794]
* **`:GoDef`** can jump to existing buffers instead of opening a new window
  (split, vsplit or tab). By default it's disabled to not break the old
  behavior, can be enabled with `let g:go_def_reuse_buffer = 1`

BUG FIXES:

* Fix not showing documentation for dot, named and package/file name being different imports [gh-332]
* Term mode: fix closing location list if result is successful after a failed attempt [gh-768]
* Syntax: fix gotexttmpl identifier highlighting [gh-778]
* Doc: fix wrong wording for `go-run` mapping. It's for the whole main package,
  not for the current file

BACKWARDS INCOMPATIBILITIES:

* `:GoDef` doesn't accept any identifier as an argument. This is not suported
  via `guru definition` and also was not widely used either. Also with this, we
  significantly simplified the existing def.vim code
* `:GoOracleScope`  and `:GoOracleTags` are deprecated in favor of
  `:GoGuruScope` and `:GoGuruTags`. Also `g:go_oracle_scope` is renamed to
  `g:go_guru_scope`
* `g:go_guru_scope` accepts a variable in type of `list` instead of `string`.
  i.g: `let g:go_guru_scope = ["github.com/fatih/structs", "golang.org/x/tools/..."]`


## Previous releases

Previous changelogs can be found here: https://github.com/fatih/vim-go/releases

