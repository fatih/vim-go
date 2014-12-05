# vim-go-coverlay
Go (golang) code coverage overlays support for Vim.

![ss-vim-go-coverlay](https://cloud.githubusercontent.com/assets/3804806/5319001/81a3b89a-7ce8-11e4-9fbd-2f0fd00ce1c7.gif)

## Install
For Vundle add these lines to your vimrc:

```
Plugin 'fatih/vim-go' "prerequisites
Plugin 't-yuki/vim-go-coverlay'
```

Then run :PluginInstall

## Mappings
For example, add these lines to your vimrc:

```vim
au FileType go nmap <leader>c <Plug>(go-coverlay) "test coverage then overlay covered lines
au FileType go nmap <leader>C <Plug>(go-clearlay) "clear overlay
```

## Thanks and Credits

* Thanks for basic structure and some of codes: https://github.com/fatih/vim-go and related projects.
* Thanks for inspiration: https://github.com/twada/coverlay.el
* Thanks for documentation: http://vim-jp.org/vimdoc-ja/eval.html
 * http://vim-jp.org/vimdoc-ja/eval.html#matchadd%28%29
 * http://vim-jp.org/vimdoc-ja/pattern.html
 * http://vim-jp.org/vimdoc-ja/options.html#%27highlight%27
 * http://www.vim.org/scripts/script.php?script_id=1238
* Thanks for parser: https://godoc.org/golang.org/x/tools/cover#ParseProfiles

