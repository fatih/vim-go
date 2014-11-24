if exists("b:did_ftplugin_go_coverlay")
	finish
endif
let b:did_ftplugin_go_coverlay = 1

" Some handy plug mappings
nnoremap <silent> <Plug>(go-coverlay) :<C-u>call go#coverlay#Coverlay('')<CR>
nnoremap <silent> <Plug>(go-clearlay) :<C-u>call go#coverlay#Clearlay('')<CR>

" coverlay
command! -nargs=* GoCoverlay call go#coverlay#Coverlay(<f-args>)
command! -nargs=* GoClearlay call go#coverlay#Clearlay(<f-args>)

" vim:ts=4:sw=4:et
