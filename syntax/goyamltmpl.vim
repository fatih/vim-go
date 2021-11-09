if exists("b:current_syntax")
  finish
endif

if !exists("g:main_syntax")
  let g:main_syntax = 'yaml'
endif

set filetype=yaml
unlet b:current_syntax

syn include @yamlGoTextTmpl syntax/gotexttmpl.vim

syn region goTextTmpl start=/{{/ end=/}}/ contains=@gotplLiteral,gotplControl,gotplFunctions,gotplVariable,goTplIdentifier containedin=ALLBUT,goTextTmpl keepend
hi def link goTextTmpl PreProc

let b:current_syntax = "goyamltmpl"

" vim: sw=2 ts=2 et

