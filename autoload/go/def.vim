function! go#def#Jump(mode) abort
  let old_gopath = $GOPATH
  let $GOPATH = go#path#Detect()

  let fname = fnamemodify(expand("%"), ':p:gs?\\?/?')

  " so guru right now is slow for some people. previously we were using
  " godef which also has it's own quirks. But this issue come up so many
  " times I've decided to support both. By default we still use guru as it
  " covers all edge cases, but now anyone can switch to godef if they wish
  let bin_name = get(g:, 'go_def_mode', 'guru')
  if bin_name == 'godef'
    if &modified
      " Write current unsaved buffer to a temp file and use the modified content
      let l:tmpname = tempname()
      call writefile(go#util#GetLines(), l:tmpname)
      let fname = l:tmpname
    endif

    let bin_path = go#path#CheckBinPath("godef")
    if empty(bin_path)
      let $GOPATH = old_gopath
      return
    endif
    let command = printf("%s -f=%s -o=%s -t", go#util#Shellescape(bin_path),
      \ go#util#Shellescape(fname), go#util#OffsetCursor())
    let out = go#util#System(command)
    if exists("l:tmpname")
      call delete(l:tmpname)
    endif
  elseif bin_name == 'guru'
    let bin_path = go#path#CheckBinPath("guru")
    if empty(bin_path)
      let $GOPATH = old_gopath
      return
    endif

    let cmd = [bin_path]
    let stdin_content = ""

    if &modified
      let content  = join(go#util#GetLines(), "\n")
      let stdin_content = fname . "\n" . strlen(content) . "\n" . content
      call add(cmd, "-modified")
    endif

    if exists('g:go_build_tags')
      let tags = get(g:, 'go_build_tags')
      call extend(cmd, ["-tags", tags])
    endif

    let fname = fname.':#'.go#util#OffsetCursor()
    call extend(cmd, ["definition", fname])

    if go#util#has_job()
      let l:spawn_args = {
            \ 'cmd': cmd,
            \ 'custom_cb': function('s:jump_to_declaration_cb', [a:mode, bin_name]),
            \ }

      if &modified
        let l:spawn_args.input = stdin_content
      endif

      call go#util#EchoProgress("searching declaration ...")

      call s:def_job(spawn_args)
      return
    endif

    let command = join(cmd, " ")
    if &modified
      let out = go#util#System(command, stdin_content)
    else
      let out = go#util#System(command)
    endif
  else
    call go#util#EchoError('go_def_mode value: '. bin_name .' is not valid. Valid values are: [godef, guru]')
    return
  endif

  if go#util#ShellError() != 0
    call go#util#EchoError(out)
    return
  endif

  call go#def#jump_to_declaration(out, a:mode, bin_name)
  let $GOPATH = old_gopath
endfunction

function! s:jump_to_declaration_cb(mode, bin_name, job, exit_status, data) abort
  if a:exit_status != 0
    return
  endif

  call go#def#jump_to_declaration(a:data[0], a:mode, a:bin_name)
  call go#util#EchoSuccess(fnamemodify(a:data[0], ":t"))
endfunction

function! go#def#jump_to_declaration(out, mode, bin_name) abort
  let final_out = a:out
  if a:bin_name == "godef"
    " append the type information to the same line so our we can parse it.
    " This makes it compatible with guru output.
    let final_out = join(split(a:out, '\n'), ':')
  endif

  " strip line ending
  let out = split(final_out, go#util#LineEnding())[0]
  if go#util#IsWin()
    let parts = split(out, '\(^[a-zA-Z]\)\@<!:')
  else
    let parts = split(out, ':')
  endif

  let filename = parts[0]
  let line = parts[1]
  let col = parts[2]
  let ident = parts[3]

  " needed for restoring back user setting this is because there are two
  " modes of switchbuf which we need based on the split mode
  let old_switchbuf = &switchbuf

  normal! m'
  if filename != fnamemodify(expand("%"), ':p:gs?\\?/?')
    " jump to existing buffer if, 1. we have enabled it, 2. the buffer is loaded
    " and 3. there is buffer window number we switch to
    if get(g:, 'go_def_reuse_buffer', 0) && bufloaded(filename) != 0 && bufwinnr(filename) != -1
      " jumpt to existing buffer if it exists
      execute bufwinnr(filename) . 'wincmd w'
    else
      if &modified
        let cmd = 'hide edit'
      else
        let cmd = 'edit'
      endif

      if a:mode == "tab"
        let &switchbuf = "useopen,usetab,newtab"
        if bufloaded(filename) == 0
          tab split
        else
           let cmd = 'sbuf'
        endif
      elseif a:mode == "split"
        split
      elseif a:mode == "vsplit"
        vsplit
      endif

      " open the file and jump to line and column
      exec cmd fnameescape(fnamemodify(filename, ':.'))
    endif
  endif
  call cursor(line, col)

  " also align the line to middle of the view
  normal! zz

  let &switchbuf = old_switchbuf
endfunction

function s:def_job(args) abort
  function! s:error_info_cb(job, exit_status, data) closure
    " do not print anything during async definition search&jump
  endfunction

  let a:args.error_info_cb = funcref('s:error_info_cb')
  let callbacks = go#job#Spawn(a:args)

  let start_options = {
        \ 'callback': callbacks.callback,
        \ 'exit_cb': callbacks.exit_cb,
        \ }

  if &modified
    let l:tmpname = tempname()
    call writefile(split(a:args.input, "\n"), l:tmpname, "b")
    let l:start_options.in_io = "file"
    let l:start_options.in_name = l:tmpname
  endif

  call job_start(a:args.cmd, start_options)
endfunction

" vim: sw=2 ts=2 et
