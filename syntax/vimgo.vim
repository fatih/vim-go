if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "vimgo"

syn match goInterface /^\S*/
syn keyword goImplements Implements

hi def link goInterface Type
hi def link goImplements Label
