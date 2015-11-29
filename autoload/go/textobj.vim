if !exists("g:go_textobj_enabled")
    let g:go_textobj_enabled = 1
endif

let s:funcDecl = '\(^\|\W\|\s\)\@<=func\(\s\|(\).*{'
let s:funcBegin = '\(^\|\W\|\s\)\@<=func\(\s\|(\)'

function! s:char()
  " Borrowed from Ingo Karkat's answer on Stack Overflow:
  " http://stackoverflow.com/a/23323958/457812
  return matchstr(getline('.'), '\%'.col('.').'c.')
endfunction

function! go#textobj#Function(mode)
  " spos used to return cursor back to orig. position upon failure
  let l:spos = getpos('.')
  let l:line = -1
  let l:lastline = 0

  while 1
    if l:line == l:lastline
      call cursor(l:spos[1], l:spos[2], l:spos[3])
      return
    endif

    let l:pos = getpos('.')
    let l:lastline = l:line
    let l:line = l:pos[1]

    " If the cursor isn't already on an opening curl, go to one
    if s:char() != '{'
      normal! [{
      if l:pos[2] == col('.') && l:pos[1] == line('.')
        call cursor(l:spos[1], l:spos[2], l:spos[3])
        return
      endif
      continue
    endif

    " Look for a boundary 'func' on this line
    if search(s:funcDecl, 'bWce', l:pos[1]) == 0
      " Skip to next opening curl unless found
      normal! [{
      continue
    end

    " 'func' found
    break
  endwhile

  " If selecting the function, use visual mode
  if a:mode == 'a'
    " Skip parentheses
    normal! vF)%h
    " See if we hit more parentheses (means last set was tuple return)
    if s:char() == ' ' || s:char() == "\t"
      normal! h%
    endif

    " Jump to boundary 'func'
    if search(s:funcBegin, 'bWc', line('.')) == 0
      " Can still fail?
      call cursor(l:spos[1], l:spos[2], l:spos[3])
      return
    endif

    " Expand other end of visual block to closing brace
    normal! o]}
  else " a:mode == 'i'
    " Otherwise visual line mode
    normal! Vi{V
  endif
endfunction
