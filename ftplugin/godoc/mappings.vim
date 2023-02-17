nnoremap <silent> <Plug>(go-doc) :<C-u>call go#doc#Open("new", "split")<CR>
nnoremap <silent> <Plug>(go-doc-tab) :<C-u>call go#doc#Open("tabnew", "tabe")<CR>
nnoremap <silent> <Plug>(go-doc-vertical) :<C-u>call go#doc#Open("vnew", "vsplit")<CR>
nnoremap <silent> <Plug>(go-doc-split) :<C-u>call go#doc#Open("new", "split")<CR>
nnoremap <silent> <Plug>(go-doc-browser) :<C-u>call go#doc#OpenBrowser()<CR>

" vim: sw=2 ts=2 et
