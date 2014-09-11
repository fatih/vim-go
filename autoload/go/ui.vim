if exists('g:go_loaded_goui')
  finish
endif
let g:go_loaded_goui = 1


function! go#ui#OpenDefinition()
    let curline = getline('.')

    " don't touch our first line and any blank line
    if curline =~ "implements" || curline =~ "^$"
        " supress information about calling this function
        echo "" 
        return
    endif

    " format: 'interface file:lnum:coln'
    let mx = '^\(^\S*\)\s*\(.\{-}\):\(\d\+\):\(\d\+\)'

    " parse it now into the list
    let tokens = matchlist(curline, mx)

    " convert to: 'file:lnum:coln'
    let expr = tokens[2] . ":" . tokens[3] . ":" .  tokens[4]

    " jump to it in a new tab, we use explicit lgetexpr so we can later change
    " the behaviour via settings (like opening in vsplit instead of tab)
    lgetexpr expr
    tab split
    ll 1

    " center the word 
    norm! zz 
endfunction

function! go#ui#CloseWindow()
    close
    echo ""
endfunction
