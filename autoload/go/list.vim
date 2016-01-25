if !exists("g:go_list_type")
    let g:go_list_type = ""
endif

" Window opens the list with the given height up to 10 lines maximum.
" Otherwise g:go_loclist_height is used. If no or zero height is given it
" closes the window
function! go#list#Window(quickfix, ...)
    let l:quickfix = go#list#Type(a:quickfix)
    " we don't use lwindow to close the location list as we need also the
    " ability to resize the window. So, we are going to use lopen and lclose
    " for a better user experience. If the number of errors in a current
    " location list increases/decreases, cwindow will not resize when a new
    " updated height is passed. lopen in the other hand resizes the screen.
    if !a:0 || a:1 == 0
        if l:quickfix == 0
            lclose
        else
            cclose
        endif
        return
    endif

    let height = get(g:, "go_list_height", 0)
    if height == 0
        " prevent creating a large location height for a large set of numbers
        if a:1 > 10
            let height = 10
        else
            let height = a:1
        endif
    endif

    if l:quickfix == 0
      exe 'lopen ' . height
    else
      exe 'copen ' . height
    endif
endfunction


" Get returns the current list of items from the location list
function! go#list#Get(quickfix)
    let l:quickfix = go#list#Type(a:quickfix)
    if l:quickfix == 0
        return getloclist(0)
    else
        return getqflist()
    endif
endfunction

" Populate populate the location list with the given items
function! go#list#Populate(quickfix, items)
    let l:quickfix = go#list#Type(a:quickfix)
    if l:quickfix == 0
        call setloclist(0, a:items, 'r')
    else
        call setqflist(a:items, 'r')
    endif
endfunction

function! go#list#PopulateWin(winnr, items)
    call setloclist(a:winnr, a:items, 'r')
endfunction

" Parse parses the given items based on the specified errorformat nad
" populates the location list.
function! go#list#ParseFormat(quickfix, errformat, items)
    let l:quickfix = go#list#Type(a:quickfix)
    " backup users errorformat, will be restored once we are finished
    let old_errorformat = &errorformat

    " parse and populate the location list
    let &errorformat = a:errformat
    if l:quickfix == 0
        lgetexpr a:items
    else
        cgetexpr a:items
    endif

    "restore back
    let &errorformat = old_errorformat
endfunction

" Parse parses the given items based on the global errorformat and
" populates the location list.
function! go#list#Parse(quickfix, items)
    let l:quickfix = go#list#Type(a:quickfix)
    if l:quickfix == 0
        lgetexpr a:items
    else
        cgetexpr a:items
    endif
endfunction

" JumpToFirst jumps to the first item in the location list
function! go#list#JumpToFirst(quickfix)
    let l:quickfix = go#list#Type(a:quickfix)
    if l:quickfix == 0
        ll 1
    else
        cc 1
    endif
endfunction

" Clean cleans the location list
function! go#list#Clean(quickfix)
    let l:quickfix = go#list#Type(a:quickfix)
    if l:quickfix == 0
        lex []
    else
        cex []
    endif
endfunction

function! go#list#Type(quickfix)
    if g:go_list_type == "locationlist"
        return 0
    elseif g:go_list_type == "quickfix"
        return 1
    else
        return a:quickfix
    endif
endfunction

" vim:ts=4:sw=4:et
