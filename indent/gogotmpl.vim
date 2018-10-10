if exists("b:did_indent")
  finish
endif

" Indent Golang templates that write Go code.
setlocal indentexpr=GetGoTmplIndent(v:lnum)
setlocal indentkeys+==else,=end

" Only define the function once.
if exists("*GetGoTmplIndent")
  finish
endif

function! GetGoTmplIndent(lnum)
  "some basic block and tackle stuff.
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

  " The value of a single shift-width
  if exists('*shiftwidth')
    let sw = shiftwidth()
  else
    let sw = &sw
  endif

  if thisl =~ 'autoindent_hint:indent' " special processing for unusual situations.
    let ind += sw
  elseif prevl =~ '^\s*{{-\=\s*\%(if\|else\|range\|with\|define\|block\).*}}' && prevl !~ '{{-\=\s*\%(end\).*}}'
    let ind += sw
  elseif thisl =~ '^\s*{{-\=\s*\%(else\|end\).*}}'
    let ind -= sw
  else
    " Otherwise, use normal go formatting rules.
    if prevl =~ ' = `[^`]*$'
      " previous line started a multi-line raw string
      return 0
    endif
    if prevl =~ '[({]\s*$' "&& !prevl =~ '^\s*{{.*}}\s*'
      " previous line opened a block
      let ind += shiftwidth()
    endif
    if prevl =~# '^\s*\(case .*\|default\):$'
      " previous line is part of a switch statement
      let ind += shiftwidth()
    endif
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
  endif

  return ind
endfunction

" vim: sw=2 ts=2 et
