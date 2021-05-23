if exists("b:did_ftplugin")
  finish
endif

runtime! ftplugin/html.vim

setlocal commentstring={{/*%s*/}}

" vim: sw=2 ts=2 et
