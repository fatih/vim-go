" Copyright 2011 The Go Authors. All rights reserved.
" Use of this source code is governed by a BSD-style
" license that can be found in the LICENSE file.

" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

scriptencoding utf-8

let s:buf_nr = -1

function! go#doc#OpenBrowser(...) abort
  let l:url = call('s:docURL', a:000)
  if l:url is ''
    call go#util#EchoWarning("could not find path for doc URL")
    return
  endif
  call go#util#OpenBrowser(l:url)
endfunction

function! s:docURL() abort
  if len(a:000) == 0
    " call go#lsp#DocLink directly instead of s:docURLFor, because s:docURLFor
    " will strip any version information from the URL.
    let [l:out, l:err] = go#lsp#DocLink()
    if !(l:err || len(l:out) is 0)
      let l:url = printf('%s/%s', go#config#DocUrl(), l:out)
    else
      let l:url = ''
    endif
  else
    let l:url = call('s:docURLFor', a:000)
  endif

  return l:url
endfunction

function! s:docURLFor(...) abort
  let l:identifier = call('s:godocIdentifier', a:000)
  if empty(l:identifier)
    return ''
  endif

  let l:pkg = l:identifier[0]
  let l:exported_name = ''
  if len(l:identifier) > 1
    let l:exported_name = l:identifier[1]
  endif

  " example url: https://godoc.org/github.com/fatih/set#Set
  return printf('%s/%s#%s', go#config#DocUrl(), l:pkg, l:exported_name)
endfunction

function! go#doc#Open(newmode, mode, ...) abort
  let l:words = a:000
  let l:package = ''
  if a:0 is 0
    let l:words = s:godocIdentifier()
    if len(l:words) is 0
      call go#util#EchoWarning("could not find doc identifier")
      return
    endif
    let l:package = l:words[0]
  endif

  if a:0 is 0 && &filetype == 'go'
    " use gopls to get documentation for go files
    let [l:out, l:err] = go#lsp#Doc()
  else
    " copy l:words before filtering so that filter() works when l:words is a:000
    let l:words = filter(copy(l:words), 'v:val != ""')
    let l:wd = go#util#Chdir(get(b:, 'go_godoc_wd', getcwd()))
    try
      let [l:out, l:err] = go#util#Exec(['go', 'doc'] + l:words)
    finally
      call go#util#Chdir(l:wd)
    endtry
  endif

  if l:err
    call go#util#EchoError(out)
    return
  endif

  call s:GodocView(a:newmode, a:mode, l:out, l:package)
endfunction

function! s:GodocView(newposition, position, content, package) abort
  " popup window
  if go#config#DocPopupWindow()
    if exists('*popup_atcursor') && exists('*popup_clear')
      call popup_clear()

      let borderchars = ['-', '|', '-', '|', '+', '+', '+', '+']
      if &encoding == "utf-8"
        let borderchars = ['─', '│', '─', '│', '┌', '┐', '┘', '└']
      endif
      call popup_atcursor(split(a:content, '\n'), {
            \ 'padding': [1, 1, 1, 1],
            \ 'borderchars': borderchars,
            \ 'border': [1, 1, 1, 1],
            \ })
    elseif has('nvim') && exists('*nvim_open_win')
      let lines = split(a:content, '\n')
      let height = 0
      let width = 0
      for line in lines
        let lw = strdisplaywidth(line)
        if lw > width
          let width = lw
        endif
        let height += 1
      endfor
      let width += 1 " right margin
      let max_height = go#config#DocMaxHeight()
      if height > max_height
        let height = max_height
      endif

      let buf = nvim_create_buf(v:false, v:true)
      call nvim_buf_set_lines(buf, 0, -1, v:true, lines)
      let opts = {
            \ 'relative': 'cursor',
            \ 'row': 1,
            \ 'col': 0,
            \ 'width': width,
            \ 'height': height,
            \ 'style': 'minimal',
            \ }
      call nvim_open_win(buf, v:true, opts)
      setlocal nomodified nomodifiable filetype=godoc
      let b:go_package_name = a:package

      " close easily with CR, Esc and q
      noremap <buffer> <silent> <CR> :<C-U>close<CR>
      noremap <buffer> <silent> <Esc> :<C-U>close<CR>
      noremap <buffer> <silent> q :<C-U>close<CR>
    endif
    return
  endif

  let l:wd = getcwd()
  " set the working directory to the directory of the current file when the
  " filetype is go so that getting doc in the doc window will work regardless
  " of what the the starting window's working directory is.
  if &filetype == 'go' && expand('%:p') isnot ''
    let l:wd = expand('%:p:h')
  endif

  " reuse existing buffer window if it exists otherwise create a new one
  let is_visible = bufexists(s:buf_nr) && bufwinnr(s:buf_nr) != -1
  if !bufexists(s:buf_nr)
    call execute(a:newposition)
    sil file `="[Godoc]"`
    let s:buf_nr = bufnr('%')
  elseif bufwinnr(s:buf_nr) == -1
    call execute(a:position)
    call execute(printf('%dbuffer', s:buf_nr))
  elseif bufwinid(s:buf_nr) != bufwinid('%')
    call win_gotoid(bufwinid(s:buf_nr))
  endif

  if &filetype == 'godoc'
    let l:wd = get(b:, 'go_godoc_wd', l:wd)
  endif

  " if window was not visible then resize it
  if !is_visible
    if a:position == "split"
      " cap window height to 20, but resize it for smaller contents
      let max_height = go#config#DocMaxHeight()
      let content_height = len(split(a:content, "\n"))
      if content_height > max_height
        exe 'resize ' . max_height
      else
        exe 'resize ' . content_height
      endif
    else
      " set a sane maximum width for vertical splits. In this case the minimum
      " that fits the godoc for package http without extra linebreaks and line
      " numbers on
      exe 'vertical resize 84'
    endif
  endif

  setlocal filetype=godoc
  let b:go_package_name = a:package
  let b:go_godoc_wd = l:wd
  setlocal bufhidden=delete
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal nobuflisted
  setlocal nocursorline
  setlocal nocursorcolumn
  setlocal iskeyword+=:
  setlocal iskeyword-=-
  setlocal modifiable

  %delete _
  call append(0, split(a:content, "\n"))
  sil $delete _
  setlocal nomodifiable
  sil normal! gg

  " close easily with enter
  noremap <buffer> <silent> <CR> :<C-U>close<CR>
  noremap <buffer> <silent> <Esc> :<C-U>close<CR>
  " make sure any key that sends an escape as a prefix (e.g. the arrow keys)
  " don't cause the window to close.
  nnoremap <buffer> <silent> <Esc>[ <Esc>[
endfunction

" returns the package and exported name. exported name might be empty.
" ie: fmt and Println
" ie: github.com/fatih/set and New
function s:godocIdentifier(...) abort
  let l:words = call('s:godocWord', a:000)
  if empty(l:words)
    return []
  endif

  let pkg = words[0]
  if len(words) == 1
    let exported_name = ''
    if &filetype is 'godoc'
      if pkg =~ '^[A-Z]'
        let exported_name = pkg
        let pkg = b:go_package_name
      endif
    endif
  else
    let exported_name = words[1]
  endif

  return [pkg, exported_name]
endfunction

function! s:godocWord(...) abort
  let l:words = a:000
  if a:0 is 0
    if &filetype isnot 'godoc'
      let [l:out, l:err] = go#lsp#DocLink()
      if !(l:err || len(l:out) is 0)
        " strip out any version string in the doc link path.
        let l:out = substitute(l:out, '@v[^/]\+', '', '')
        let words = split(l:out, '#')
      else
        let l:words = s:godocCursorWord()
      endif
    else
      let l:words = s:godocCursorWord()
    endif
  endif

  return l:words
endfunction

function! s:godocCursorWord() abort
  let l:oldiskeyword = &iskeyword
  " TODO(bc): include / in iskeyword when filetype is godoc?
  setlocal iskeyword+=.
  let l:word = expand('<cword>')
  let &iskeyword = l:oldiskeyword
  let l:word = substitute(l:word, '[^a-zA-Z0-9\\/._~-]', '', 'g')
  return split(l:word, '\.\ze[^./]\+$')
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et
