" Copyright 2015 Auburn University and The Go Authors. All rights reserved.
" Use of this source code is governed by a BSD-style
" license that can be found in the LICENSE file.

" Vim integration for the Go Doctor.

" NOTE: this code has been copied and adapted from github.com/godoctor/godoctor.vim

" TODO: If a refactoring only affects a single file, allow unsaved buffers
" and pipe the current buffer's contents into the godoctor via stdin
" (n.b. the quickfix list needs to be given a real filename to point to
" errors, so the godoctor's use of -.go and /dev/stdin in the log aren't good
" enough)
" TODO: Pass an option to the godoctor to limit the number of modifications.
" If it's going to try to open 100 new buffers, fail.  Consider a fallback
" option to write files in-place.

" NOTES
" -- Windows and buffers:
" http://vimdoc.sourceforge.net/htmldoc/windows.html
" -- Simulating hyperlinks in Vim:
" http://stackoverflow.com/questions/10925030/vimscriptl-file-browser-hyperlink
" -- Shell escaping/temp file problems under Windows
" http://vim.wikia.com/wiki/Fix_errors_that_relate_to_reading_or_creating_files_in_the_temp_or_tmp_environment_on_an_MS_Windows_PC
" -- Inserting the contents of a variable into a buffer
" http://stackoverflow.com/questions/16833217/set-buffer-content-with-variable
" -- Calling a varargs function
" http://stackoverflow.com/questions/11703297/how-can-i-pass-varargs-to-another-function-in-vimscript
" -- Trim whitespace from a string
" http://newsgroups.derkeiler.com/Archive/Comp/comp.editors/2005-08/msg00226.html
" -- Go Doctor ASCII art uses the AMC 3 Line font, generated here:
" http://patorjk.com/software/taag/#p=display&v=3&f=AMC%203%20Line&t=Go%20Doctor
" -- General Vimscript reference:
" http://vimdoc.sourceforge.net/htmldoc/eval.html

if exists("b:did_ftplugin_doc")
    finish
endif

if exists("g:loaded_doctor")
    finish
endif
let g:loaded_doctor = 1

" Get the path to the godoctor executable.  Run once to assign s:go_doctor.
func! go#godoctor#GoDoctorBin()
  let [ext, sep] = (has('win32') || has('win64') ? ['.exe', ';'] : ['', ':'])
  let go_doctor = globpath(join(split($GOPATH, sep), ','), '/bin/godoctor' . ext)
  if go_doctor == ''
    let go_doctor = 'godoctor' . ext
  endif
  return go_doctor
endfunction

" Path to the godoctor executable
let s:go_doctor = go#godoctor#GoDoctorBin()

" Return 0 if the given refactoring can only change the file in the editor,
" or 1 if it may affect other files as well.
function! go#godoctor#IsMultiFile(refac)
  let out = system(printf('%s --list', s:go_doctor))
  if v:shell_error
    return 1
  endif
  let result = ""
  let lines = split(out, "\n")
  if len(lines) > 2
    for line in lines[2:]
      let fields = split(line, "\t")
      if len(fields) >= 3
        let name = substitute(fields[0], "^\\s\\+\\|\\s\\+$", "", "g") 
        let multi = substitute(fields[2], "^\\s\\+\\|\\s\\+$", "", "g") 
        if name ==? a:refac
          return multi ==? "true"
        endif
      endif
    endfor
  endif
  return 1
endfun

" Parse the godoctor -complete output and store files' contents in a
" dictionary mapping filenames to their contents.
"
" When given the "-complete" flag, the Go Doctor's output has the form:
"     log message
"     log message
"     ...
"     log message
"     @@@@@ filename1 @@@@@ num_bytes @@@@@
"     file1 contents
"     file1 contents
"     @@@@@ filename2 @@@@@ num_bytes @@@@@
"     file2 contents
"     ...
"     @@@@@ filenamen @@@@@ num_bytes @@@@@
"     filen contents
func! go#godoctor#ParseFiles(output)
  let result = {}
  let pattern = '@@@@@ \([^@]\+\) @@@@@ \(\d\+\) @@@@@\(\|\r\)\n'
  let start = match(a:output, pattern, 0)

  " Repeatedly find a @@@@@ line
  while start >= 0
    let match = matchlist(a:output, pattern, start)
    if match == []
      return result
    endif
    let linelen = len(match[0])
    let filename = match[1]

    " This file's contents ends just before the start of the next @@@@@ line
    let nextmatch = match(a:output, pattern, start+linelen)
    if nextmatch < 0
      let contents = a:output[start+linelen : ]
    else
      let contents = a:output[start+linelen : nextmatch-1]
    endif
    let result[filename] = contents

    " We know the location of the next @@@@@ line, so search there next
    let start = nextmatch
  endwhile

  return result
endfun

" List of all buffers modified by the most recent refactoring
let g:allbuffers = []

" List of new buffers opened by the most recent refactoring
let g:newbuffers = []

" Open all refactored files in (hidden) buffers.
func! go#godoctor#LoadFiles(files, used_stdin)
  " Save original view
  let view = winsaveview()
  let orig = bufnr("%")

  if &hidden == 0
    set hidden
  endif
  let g:allbuffers = []
  let g:newbuffers = []
  for file in keys(a:files)
    if a:used_stdin
      " Use current buffer
      let oldnr = bufnr('%')
      let nr = bufnr('%')
    else
      " Get or create buffer, and fill with refactored file contents
      let oldnr = bufnr(fnameescape(file))
      exec "badd ".fnameescape(file)
      let nr = bufnr(fnameescape(file))
    endif
    call add(g:allbuffers, nr)
    if oldnr < 0
      call add(g:newbuffers, nr)
    endif
    silent exec "buffer! ".nr
    silent :1,$delete
    silent :put =a:files[file]
    silent :1delete _
  endfor

  " Restore original cursor position, windows, etc.
  silent exec "buffer! ".orig
  call winrestview(view)

  " If >1 file modified, display hyperlinks to make saving and undoing easier
  if len(a:files) > 1
    exec "topleft 3new"
    call setline(1, "Save Changes & Close New Buffers     " .
                  \ "  .-. .-.   .-. .-. .-. .-. .-. .-.  ")
    call setline(2, "Undo Changes & Close New Buffers     " .
                  \ "  |.. | |   |  )| | |    |  | | |(   ")
    call setline(3, "Save Changes                         " .
                  \ "  `-' `-'   `-' `-' `-'  '  `-' ' '  ")
    call setline(4, "Undo Changes")
    call setline(5, "Close This Window")
    setlocal nomodifiable buftype=nofile bufhidden=wipe nobuflisted noswapfile
    " Fix its height so, e.g., it doesn't grow when quickfix list is closed
    setlocal wfh
    " Hyperlink each line to be interpreted by go#godoctor#Interpret
    nnoremap <silent> <buffer> <CR> :call <sid>interpret(getline('.'))<CR>
  endif
endfun

" Callback for hyperlinks displayed above (to save, undo, and close buffers)
func! go#godoctor#Interpret(cmd)
  if winnr('$') > 1
    close
  endif
  let view = winsaveview()
  let orig = bufnr("%")

  if a:cmd =~ "Save Changes"
    for buf in g:allbuffers
      if bufexists(buf)
        silent exec "buffer! " . buf . " | w"
      endif
    endfor
  elseif a:cmd =~ "Undo Changes"
    for buf in g:allbuffers
      if bufexists(buf)
        silent exec "buffer! " . buf . " | undo"
      endif
    endfor
  endif
  cclose

  if bufexists(orig)
    silent exec "buffer! ".orig
  endif
  call winrestview(view)

  if a:cmd =~ "Close New"
    for buf in g:newbuffers
      if buf != orig && bufexists(buf)
        silent exec buf . "bwipeout!"
      endif
    endfor
  endif

  let g:allbuffers = []
  let g:newbuffers = []
endfunc

" Populate the quickfix list with the refactoring log, and populate each
" window's location list with the positions the refactoring modified.
func! go#godoctor#QFLocList(output, used_stdin)
  let has_errors = 0
  let qflist = []
  let loclists = {}
  " Parse GNU-style 'file:line.col-line.col: message' format.
  let mx = '^\(\a:[\\/][^:]\+\|[^:]\+\):\(\d\+\):\(\d\+\):\(.*\)$'
  for line in split(a:output, "\n")
    if line =~ '^@@@@@'
      " The log is displayed before files' contents, so as soon as we see a
      " @@@@@ line, we have seen the last log message; no need to keep looking
      break
    endif
    let ml = matchlist(line, mx)
    " Ignore non-match lines or warnings
    if ml == []
      let item = {
      \  'bufnr': bufnr('%'),
      \  'text': line,
      \}
    else
      if a:used_stdin
        let item = {
        \  'bufnr': bufnr('%'),
        \  'lnum': ml[2],
        \  'col': ml[3],
        \  'text': ml[4],
        \}
        let bname = bufname('%')
        if bname != ""
          let item['filename'] = bname
        endif
      else
        let item = {
        \  'filename': ml[1],
        \  'lnum': ml[2],
        \  'col': ml[3],
        \  'text': ml[4],
        \}
        let bnr = bufnr(fnameescape(ml[1]))
        if bnr != -1
          let item['bufnr'] = bnr
        endif
      endif
    endif
    if item['text'] =~ 'rror:'
      let item['type'] = 'E'
      let has_errors = 1
    elseif item['text'] =~ 'arning:'
      let item['type'] = 'W'
    else
      let item['type'] = 'I'
    endif
    if has_key(item, 'filename') && item['text'] =~ '^ | '
      if !has_key(loclists, item['filename'])
        let loclists[item['filename']] = []
      endif
      call add(loclists[item['filename']], item)
    else
      call add(qflist, item)
    endif
  endfor
  for f in keys(loclists)
    let list = loclists[f]
    let nr = bufwinnr(f)
    if nr > 0
      call setloclist(nr, list)
    endif
  endfor
  call setqflist(qflist)
  if empty(qflist)
    cclose
  else
    if has_errors
      " cwindow only opens the quickfix list when there are errors that are
      " associated with a file position.  This ensures that it will be opened
      " even if there are generic errors not associated with a file position.
      copen
    else
      cwindow
    endif
  endif
endfun

" Run the Go Doctor with the given selection, refactoring name, and arguments.
func! go#godoctor#RunDoctor(selected, refac, ...) range abort
  let multifile = go#godoctor#IsMultiFile(a:refac)
  let cur_buf_file = expand('%:p')
  let bufcount = bufnr('$')

  " The current buffer contents can be sent to the godoctor on stdin if
  " (1) there are no other unsaved buffers, and
  " (2) the current buffer is unnamed (i.e., it is a new file).
  " So, check that there is at most one unsaved buffer, and it has no name.

  for i in range(1, bufcount)
    if bufexists(i) && getbufvar(i, "&mod") && bufname(i) != ""
      echohl Error
         \ | echom bufname(i) . " has unsaved changes; please save before refactoring"
         \ | echohl None
      return
    endif
  endfor

  let s:scope = ""

  " set scope from func, if exists. allow hard g:doctor_scope to override
  if exists("*DoctorScopeFunc")
    let s:scope = " -scope=".shellescape(DoctorScopeFunc())
  endif

  if exists("g:doctor_scope")
    let s:scope = " -scope=".shellescape(g:doctor_scope)
  endif

  if cur_buf_file == ""
    " Read file from standard input
    let file = " -file=-"
  else
    let file = printf(" -file=%s", cur_buf_file)
  endif

  if a:selected != -1
    let pos = printf(" -pos=%d,%d:%d,%d",
      \ line("'<"), col("'<"),
      \ line("'>"), col("'>"))
  else
    let pos = printf(" -pos=%d,%d:%d,%d",
      \ line('.'), col('.'),
      \ line('.'), col('.'))
  endif
  let cmd = printf('%s -v -complete%s%s%s %s %s',
    \ s:go_doctor,
    \ s:scope,
    \ file,
    \ pos,
    \ shellescape(a:refac),
    \ join(map(copy(a:000), 'shellescape(v:val)'), ' '))
  if cur_buf_file == ""
    let cur_buf_contents = join(getline(1,'$'), "\n")
    if cur_buf_contents == ""
      echohl Error
        \ | echom "The current buffer is empty; cannot refactor"
        \ | echohl None
      return
    endif
    let out = system(cmd, cur_buf_contents)
  else
    let out = system(cmd)
  endif
  " echo cmd
  " echo out
  if v:shell_error
    let lines = split(out, "\n")
    echohl Error | echom lines[0] | echohl None
  endif
  let files = go#godoctor#ParseFiles(out)
  call go#godoctor#LoadFiles(files, cur_buf_file == "")
  call go#godoctor#QFLocList(out, cur_buf_file == "")
endfun

" List the available refactorings, one per line.  Used for auto-completion.
function! go#godoctor#ListRefacs(a, l, p)
  let out = system(printf('%s --list', s:go_doctor))
  if v:shell_error
    return ""
  endif
  let result = ""
  let lines = split(out, "\n")
  if len(lines) > 2
    for line in lines[2:]
      let fields = split(line, "\t")
      if len(fields) >= 1
        let name = substitute(fields[0], "^\\s\\+\\|\\s\\+$", "", "g") 
        let result = result . name . "\n"
      endif
    endfor
  endif
  return result
endfun

" Run the Extract refactoring with the given arguments.  If a new name is not
" provided, prompt for one.
func! go#godoctor#Extract(selected, ...) range abort
  if len(a:000) > 0
    call call("go#godoctor#RunDoctor", [a:selected, 'extract'] + a:000)
  else
    let input = inputdialog("Enter function name: ")
    if input == ""
      echo ""
    else
      call go#godoctor#RunDoctor(a:selected, 'extract', input)
    endif
  endif
endfun

command! -range=% -nargs=+ GoExtract
  \ call go#godoctor#Extract(<count>, <f-args>)

""" TODO: introduce full godoctor integration here? 
""" (some feature overlap with gorename)
"command! -range=% -nargs=+ -complete=custom,<sid>list_refacs GoDoctor
"  \ call go#godoctor#RunDoctor(<count>, <f-args>)

let b:did_ftplugin_doc = 1

" vim:ts=2:sw=2:et
