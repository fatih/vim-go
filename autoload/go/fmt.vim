" Copyright 2011 The Go Authors. All rights reserved.
" Use of this source code is governed by a BSD-style
" license that can be found in the LICENSE file.
"
" fmt.vim: Vim command to format Go files with gofmt (and gofmt compatible
" toorls, such as goimports).

" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! go#fmt#Format(withGoimport) abort
  let l:lines = getbufline(bufnr('%'), 1, '$')
  let l:filepath = expand("%")

  let l:out = go#fmt#run(a:withGoimport, l:lines, l:filepath)

  if empty(l:out)
    return
  endif

  if l:out == l:lines
    return
  endif

  " replace buffer with formatted lines
  call go#fmt#replace(l:out)

  call go#lsp#DidChange(expand(l:filepath, ':p'))
endfunction


function! go#fmt#run(withGoimport, lines, filepath) abort
  let l:bin_name = go#config#FmtCommand()
  if a:withGoimport == 1
    let l:mode = go#config#ImportsMode()
    if l:mode == 'gopls'
      if !go#config#GoplsEnabled()
        call go#util#EchoError("go_imports_mode is 'gopls', but gopls is disabled")
        return
      endif
      call go#lsp#Imports()
      return
    endif

    let l:bin_name = 'goimports'
  endif

  if l:bin_name == 'gopls'
    if !go#config#GoplsEnabled()
      call go#util#EchoError("go_def_mode is 'gopls', but gopls is disabled")
      return
    endif
    call go#lsp#Format()
    return
  endif

  let l:cmd = join(s:fmt_cmd(l:bin_name, a:filepath), " ")

  " format with specified command
  let l:out = split(system(l:cmd, a:lines), '\n')

  " check system exit code
  if v:shell_error
    if !go#config#FmtFailSilently()
      let l:errors = s:replace_filename(expand('%'), l:out)
      call go#fmt#ShowErrors(l:errors)
    endif

    return
  endif

  return l:out
endfunction

function! go#fmt#replace(lines) abort
  " store view
  if go#config#FmtExperimental()
    " Using winsaveview to save/restore cursor state has the problem of
    " closing folds on save:
    "   https://github.com/fatih/vim-go/issues/502
    " One fix is to use mkview instead. Unfortunately, this sometimes causes
    " other bad side effects:
    "   https://github.com/fatih/vim-go/issues/728
    " and still closes all folds if foldlevel>0:
    "   https://github.com/fatih/vim-go/issues/732
    let l:curw = {}
    try
      mkview!
    catch
      let l:curw = winsaveview()
    endtry

    " save our undo file to be restored after we are done. This is needed to
    " prevent an additional undo jump due to BufWritePre auto command and also
    " restore 'redo' history because it's getting being destroyed every
    " BufWritePre
    let tmpundofile = tempname()
    exe 'wundo! ' . tmpundofile
  else
    let l:curw = winsaveview()
  endif

  " we should not replace contents if the newBuffer is empty
  if empty(a:lines)
    return
  endif

  " https://vim.fandom.com/wiki/Restore_the_cursor_position_after_undoing_text_change_made_by_a_script
  " create a fake change entry and merge with undo stack prior to do formating
  normal! ix
  normal! x
  try | silent undojoin | catch | endtry

  " delete all lines on the current buffer
  silent! execute '%delete _'

  " replace all lines from the current buffer with output
  let l:idx = 0
  for l:line in a:lines
    silent! call append(l:idx, l:line)
    let l:idx += 1
  endfor
  
  " delete trailing newline introduced by the above append procedure
  silent! execute '$delete _'

  " restore view
  if go#config#FmtExperimental()
    " restore our undo history
    silent! exe 'rundo ' . tmpundofile
    call delete(tmpundofile)

    " Restore our cursor/windows positions, folds, etc.
    if empty(l:curw)
      silent! loadview
    else
      call winrestview(l:curw)
    endif
  else
    call winrestview(l:curw)
  endif
    
  " syntax highlighting breaks less often
  syntax sync fromstart
endfunction

" fmt_cmd returns the command to run as a list.
function! s:fmt_cmd(bin_name, filepath)
  let l:cmd = [a:bin_name]

  " add the options for binary (if any). go_fmt_options was by default of type
  " string, however to allow customization it's now a dictionary of binary
  " name mapping to options.
  let opts = go#config#FmtOptions()
  if type(opts) == type({})
    let opts = has_key(opts, a:bin_name) ? opts[a:bin_name] : ""
  endif
  call extend(cmd, split(opts, " "))
  if a:bin_name is# 'goimports'
    call extend(cmd, ["-srcdir", a:filepath])
  endif

  return cmd
endfunction

" replace_filename replaces the filename on each line of content with
" a:filename.
function! s:replace_filename(filename, errors) abort
  let l:errors = map(a:errors, printf('substitute(v:val, ''^.\{-}:'', ''%s:'', '''')', a:filename))
  return join(l:errors, "\n")
endfunction

function! go#fmt#CleanErrors() abort
  let l:listtype = go#list#Type("GoFmt")

  " clean up previous list
  if l:listtype == "quickfix"
    let l:list_title = getqflist({'title': 1})
  else
    let l:list_title = getloclist(0, {'title': 1})
  endif

  if has_key(l:list_title, 'title') && (l:list_title['title'] == 'Format' || l:list_title['title'] == 'GoMetaLinterAutoSave')
    call go#list#Clean(l:listtype)
  endif
endfunction

" show_errors opens a location list and shows the given errors. If errors is
" empty, it closes the the location list.
function! go#fmt#ShowErrors(errors) abort
  let l:errorformat = '%f:%l:%c:\ %m'
  let l:listtype = go#list#Type("GoFmt")

  call go#list#ParseFormat(l:listtype, l:errorformat, a:errors, 'Format', 0)
  let l:errors = go#list#Get(l:listtype)

  " this closes the window if there are no errors or it opens
  " it if there are any.
  call go#list#Window(l:listtype, len(l:errors))
endfunction

function! go#fmt#ToggleFmtAutoSave() abort
  if go#config#FmtAutosave()
    call go#config#SetFmtAutosave(0)
    call go#util#EchoProgress("auto fmt disabled")
    return
  end

  call go#config#SetFmtAutosave(1)
  call go#util#EchoProgress("auto fmt enabled")
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et
