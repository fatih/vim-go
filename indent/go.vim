" Copyright 2011 The Go Authors. All rights reserved.
" Use of this source code is governed by a BSD-style
" license that can be found in the LICENSE file.
"
" indent/go.vim: Vim indent file for Go.
"
" TODO:
" - general line splits (line ends in an operator)

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

" C indentation is too far off useful, mainly due to Go's := operator.
" Let's just define our own.
setlocal nolisp
setlocal autoindent
setlocal indentexpr=GoIndent(v:lnum)
setlocal indentkeys+=<:>,0=},0=)

if exists("*GoIndent")
  finish
endif

function! s:is_string_comment(lnum, col)
  if !has('syntax_items')
    return 0
  endif

  for id in synstack(a:lnum, a:col)
    let synname = synIDattr(id, "name")
    if synname == "goComment" || synname == "goString" || synname == "goRawString"
      return 1
    endif
  endfor
endfunction

function! GoIndent(lnum)
  let prevlnum = prevnonblank(a:lnum-1)
  if prevlnum == 0
    " top of file
    return 0
  endif

  " grab the previous and current line, stripping comments.
  let prevl = substitute(getline(prevlnum), '//.*$', '', '')
  let thisl = substitute(getline(a:lnum), '//.*$', '', '')
  let previ = indent(prevlnum)

  let ind = previ

  if prevl =~ ' = `[^`]*$'
    " previous line started a multi-line raw string
    return 0
  endif
  call cursor(a:lnum, 1)
  let openline = searchpair('{\|(', '', '}\|)', 'nbW',
    \ 's:is_string_comment(line("."), col("."))')
  if openline != 0
    " We're inside of a block so we indent one level
    let ind = indent(openline) + shiftwidth()
  endif
  if prevl =~# '^\s*\(case .*\|default\):$'
    " previous line is part of a switch statement
    let ind += shiftwidth()
  endif
  " TODO: handle if the previous line is a label.

  if thisl =~ '^\s*[)}]'
    " this line closed a block
    let ind -= shiftwidth()
  endif

  " Colons are tricky.
  " We want to outdent if it's part of a switch ("case foo:" or "default:").
  " We ignore trying to deal with jump labels because (a) they're rare, and
  " (b) they're hard to disambiguate from a composite literal key.
  if thisl =~# '^\s*\(case .*\|default\):$'
    let ind -= shiftwidth()
  endif

  return ind
endfunction

" vim: sw=2 ts=2 et
