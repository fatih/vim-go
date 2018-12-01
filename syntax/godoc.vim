if exists('b:current_syntax')
    finish
endif

syn include @godocGoSrc syntax/go.vim
syn match godocGoRegion /\%^\%(\%(.\+\n\)\+\n\)\{2}/ contains=@godocGoSrc

let b:current_syntax = 'godoc'
