"
" https://github.com/fatih/vim-go/issues/807
" https://github.com/cweill/gotests
" https://github.com/cweill/gotests/issues/20
"

if !exists("g:go_gotests_bin")
    let g:go_gotests_bin = "gotests"
endif

" Append output of gotests to corresponding _test.go file
function! go#test#TableTests(bang, ...)
    let func = search('^func ', "bcnW")

    if func == 0
        echo "vim-go: no func found previous to cursor"
        return
    end

    let line = getline(func)
    let fname = split(split(line, " ")[1], "(")[0]

    " Check if binary exists
    let bin_path = go#path#CheckBinPath(g:go_gotests_bin)
    if empty(bin_path)
        return
    endif

    let file = expand('%')

    " Shouldn't happen as this function shouldn't be registered
    if empty(file)
        call go#util#EchoError("vim-go: write go file to disk first")
        return
    endif

    " Ensure changes are written to disk for tool to read updated version
    if &modified
        call go#util#EchoError("vim-go: unsaved changes in buffer")
        return
    endif

    " Run gotests
    let out = system(bin_path . ' -w -only ^' . shellescape(fname) . '$ ' . shellescape(file))

    if v:shell_error
        call go#util#EchoError("vim-go: gotests error: " . out)
    endif
endfunction
