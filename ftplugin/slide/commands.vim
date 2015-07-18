if exists("g:slide_loaded_commands")
    finish
endif
let g:slide_loaded_commands = 1

" -- Present
command! -nargs=0 -range=% GoPresent call slide#present#Present(expand('%:t'))

" vim:ts=4:sw=4:et
