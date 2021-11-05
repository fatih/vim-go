" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! s:code(group, attr) abort
  let code = synIDattr(synIDtrans(hlID(a:group)), a:attr, "cterm")
  if code =~ '^[0-9]\+$'
    return code
  endif
endfunction

function! s:color(str, group) abort
  let fg = s:code(a:group, "fg")
  let bg = s:code(a:group, "bg")
  let bold = s:code(a:group, "bold")
  let italic = s:code(a:group, "italic")
  let reverse = s:code(a:group, "reverse")
  let underline = s:code(a:group, "underline")
  let color = (empty(fg) ? "" : ("38;5;".fg)) .
            \ (empty(bg) ? "" : (";48;5;".bg)) .
            \ (empty(bold) ? "" : ";1") .
            \ (empty(italic) ? "" : ";3") .
            \ (empty(reverse) ? "" : ";7") .
            \ (empty(underline) ? "" : ";4")
  return printf("\x1b[%sm%s\x1b[m", color, a:str)
endfunction

function! s:source(mode,...) abort
  let s:current_dir = expand('%:p:h')
  let ret_decls = []

  let l:cmd = ['motion',
        \ '-format', 'vim',
        \ '-mode', 'decls',
        \ '-include', go#config#DeclsIncludes(),
        \ ]

  call go#cmd#autowrite()

  if a:mode == 0
    " current file mode
    let l:fname = expand("%:p")
    if a:0 && !empty(a:1)
      let l:fname = a:1
    endif

    let cmd += ['-file', l:fname]
  else
    " all functions mode
    if a:0 && !empty(a:1)
      let s:current_dir = a:1
    endif

    let l:cmd += ['-dir', s:current_dir]
  endif

  let [l:out, l:err] = go#util#Exec(l:cmd)
  if l:err
    call go#util#EchoError(l:out)
    return
  endif

  let result = eval(out)
  if type(result) != 4 || !has_key(result, 'decls')
    return ret_decls
  endif

  let decls = result.decls

  " find the maximum function name
  let max_len = 0
  for decl in decls
    if len(decl.ident)> max_len
      let max_len = len(decl.ident)
    endif
  endfor

  for decl in decls
    " paddings
    let space = " "
    for i in range(max_len - len(decl.ident))
      let space .= " "
    endfor

    let pos = printf("|%s:%s:%s|",
          \ fnamemodify(decl.filename, ":t"),
          \ decl.line,
          \ decl.col
          \)
    call add(ret_decls, printf("%s\t%s\t%s\t%s",
          \ s:color(decl.ident . space, "goDeclsFzfFunction"),
          \ s:color(decl.keyword, "goDeclsFzfKeyword"),
          \ s:color(decl.full, "goDeclsFzfComment"),
          \ s:color(pos, "goDeclsFzfSpecialComment"),
          \))
  endfor

  return sort(ret_decls)
endfunc

function! fzf#decls#cmd(...) abort
  let normal_fg = s:code("Normal", "fg")
  let normal_bg = s:code("Normal", "bg")
  let cursor_fg = s:code("CursorLine", "fg")
  let cursor_bg = s:code("CursorLine", "bg")
  let colors = printf(" --color %s%s%s%s%s",
        \ &background,
        \ empty(normal_fg) ? "" : (",fg:".normal_fg),
        \ empty(normal_bg) ? "" : (",bg:".normal_bg),
        \ empty(cursor_fg) ? "" : (",fg+:".cursor_fg),
        \ empty(cursor_bg) ? "" : (",bg+:".cursor_bg),
        \)
  call fzf#run(fzf#wrap('GoDecls', {
        \ 'source': call('<sid>source', a:000),
        \ 'options': printf('-n 1 --with-nth 1,2 --delimiter=$''\t'' --preview "echo {3}" --preview-window "wrap" --ansi --prompt "GoDecls> " --expect=ctrl-t,ctrl-v,ctrl-x%s', colors),
        \ 'sink*': function('fzf#fzf#sink')
        \ }))
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et
