" Copyright 2011 The Go Authors. All rights reserved.
" Use of this source code is governed by a BSD-style
" license that can be found in the LICENSE file.
"
" indent/go.vim: Vim indent file for Go.
"
" TODO:
" - function invocations split across lines
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

" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! GoIndent(lnum) abort
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

  for synid in synstack(a:lnum, 1)
    if synIDattr(synid, 'name') == 'goRawString'
      if prevl =~ '\%(\%(:\?=\)\|(\|,\)\s*`[^`]*$'
        " previous line started a multi-line raw string
        return 0
      endif
      " return -1 to keep the current indent.
      return -1
    endif
  endfor

  let num_parenthases = s:CountIndent(prevl, '(', ')')
  let num_brackets = s:CountIndent(prevl, '{', '}')

  if num_parenthases > 0 || num_brackets > 0
    " previous line opened a block
    let ind += shiftwidth()
  endif
  if prevl =~# '^\s*\(case .*\|default\):$'
    " previous line is part of a switch statement
    let ind += shiftwidth()
  endif
  " TODO: handle if the previous line is a label.

  let num_parenthases = s:CountIndent(thisl, '(', ')')
  let num_brackets = s:CountIndent(thisl, '{', '}')

  if num_parenthases < 0 || num_brackets < 0
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

" Returns the indent level after the given line.
" Line comments are handled before this is called,
" so this function does not check for them. It does
" check for strings and block comments.
function! s:CountIndent(line, open_char, close_char)
  let in_string = 0
  let in_comment = 0
  let level = 0
  let prev_c = ''

  " Iterate through all characters in line
  for c in split(a:line, '\zs')
    " Strings cannot start within a comment,
    " and comments cannot start/stop in a string.
    if !in_comment
      " Make sure strings don't effect indent
      if c == '"' || c == '`'
        let in_string = !in_string
      end
    endif

    if !in_string
      " Make sure block comments don't effect indent
      if prev_c == '/' && c == '*'
        let in_comment = 1
      endif
      if prev_c == '*' && c == '/'
        let in_comment = 0
      endif
    endif

    if !in_string && !in_comment
      if c == a:open_char
        let level += 1
      elseif c == a:close_char
        let level -= 1
      endif
    endif
    let prev_c = c
  endfor

  return level
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et
