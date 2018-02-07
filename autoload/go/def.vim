let s:go_stack = []
let s:go_stack_level = 0

let s:last_res = {}
let s:last_job = test_null_job()

function! go#def#Compute(mode, jump) abort
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
      return {'err': "godef path not found"}
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
      return {'err': "guru not found"}
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
      let l:spawn_args = {'cmd': cmd}
      let l:spawn_args.complete = function('s:store_result_cb', [a:mode, bin_name])
      if a:jump
        let l:spawn_args.complete = function('s:jump_to_declaration_cb', [a:mode, bin_name])
      endif

      if &modified
        let l:spawn_args.input = stdin_content
      endif

      if get(g:, 'go_echo_command_info', 1)
        call go#util#EchoProgress("searching declaration ...")
      endif

      let s:last_job = s:def_job(spawn_args)
      return {'is_job': 1}
    endif

    let command = join(cmd, " ")
    if &modified
      let out = go#util#System(command, stdin_content)
    else
      let out = go#util#System(command)
    endif
  else
    return {'err': printf("go_def_mode value: %s is not valid. Valid values are: [godef, guru]", bin_name)}
  endif

  if go#util#ShellError() != 0
    return {'err': out}
  endif

  return {"out": out, "bin_name": bin_name}
endfunction


function! go#def#Jump(mode) abort
  " if there is a job running that was already triggered by the auto
  " definition event, cancel it and re-trigger the computation from start
  " below. This is so we avoid race conditions between a manual trigger and
  " auto trigger. Later we can improve it even further by intercepting
  " `store_result_cb` to not store the result and instead to jump directly if
  " we try to jump in midflight. This needs more work imho.
  if !empty(s:last_job) && job_status(s:last_job) == "run"
    call job_stop(s:last_job) 

    " clear any old cache entries
    let s:last_res = {}
    let s:last_job = test_null_job()
  endif

  " use the pre-fetched result, if there is any.
  let result = s:last_res
  if !empty(s:last_res)
    call go#def#jump_to_declaration(result.out, a:mode, result.bin_name)
    return
  endif

  let result = go#def#Compute(a:mode, 1)
  if has_key(result, 'err')
    call go#util#EchoError(result.err)
    return -1
  endif

  " this is the case if auto trigger was cancelled above or if there is no
  " auto definition enabled at all. In both cases we're going to jump through
  " the jump callback
  if has_key(result, 'is_job')
    return 0
  endif

  call go#def#jump_to_declaration(result.out, a:mode, result.bin_name)
endfunction

function! s:jump_to_declaration_cb(mode, bin_name, job, exit_status, data) abort
  if a:exit_status != 0
    return
  endif

  call go#def#jump_to_declaration(a:data[0], a:mode, a:bin_name)
  call go#util#EchoSuccess(fnamemodify(a:data[0], ":t"))
endfunction

function! s:store_result_cb(mode, bin_name, job, exit_status, data) abort
  if a:exit_status != 0
    return
  endif

  let s:last_res = {'out': a:data[0], 'bin_name': a:bin_name}
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

  " Remove anything newer than the current position, just like basic
  " vim tag support
  if s:go_stack_level == 0
    let s:go_stack = []
  else
    let s:go_stack = s:go_stack[0:s:go_stack_level-1]
  endif

  " increment the stack counter
  let s:go_stack_level += 1

  " push it on to the jumpstack
  let stack_entry = {'line': line("."), 'col': col("."), 'file': expand('%:p'), 'ident': ident}
  call add(s:go_stack, stack_entry)

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

function! go#def#SelectStackEntry() abort
  let target_window = go#ui#GetReturnWindow()
  if empty(target_window)
    let target_window = winnr()
  endif

  let highlighted_stack_entry = matchstr(getline("."), '^..\zs\(\d\+\)')
  if !empty(highlighted_stack_entry)
    execute target_window . "wincmd w"
    call go#def#Stack(str2nr(highlighted_stack_entry))
  endif

  call go#ui#CloseWindow()
endfunction

function! go#def#StackUI() abort
  if len(s:go_stack) == 0
    call go#util#EchoError("godef stack empty")
    return
  endif

  let stackOut = ['" <Up>,<Down>:navigate <Enter>:jump <Esc>,q:exit']

  let i = 0
  while i < len(s:go_stack)
    let entry = s:go_stack[i]
    let prefix = ""

    if i == s:go_stack_level
      let prefix = ">"
    else
      let prefix = " "
    endif

    call add(stackOut, printf("%s %d %s|%d col %d|%s",
          \ prefix, i+1, entry["file"], entry["line"], entry["col"], entry["ident"]))
    let i += 1
  endwhile

  if s:go_stack_level == i
    call add(stackOut, "> ")
  endif

  call go#ui#OpenWindow("GoDef Stack", stackOut, "godefstack")

  noremap <buffer> <silent> <CR>  :<C-U>call go#def#SelectStackEntry()<CR>
  noremap <buffer> <silent> <Esc> :<C-U>call go#ui#CloseWindow()<CR>
  noremap <buffer> <silent> q     :<C-U>call go#ui#CloseWindow()<CR>
endfunction

function! go#def#StackClear(...) abort
  let s:go_stack = []
  let s:go_stack_level = 0
endfunction

function! go#def#StackPop(...) abort
  if len(s:go_stack) == 0
    call go#util#EchoError("godef stack empty")
    return
  endif

  if s:go_stack_level == 0
    call go#util#EchoError("at bottom of the godef stack")
    return
  endif

  if !len(a:000)
    let numPop = 1
  else
    let numPop = a:1
  endif

  let newLevel = str2nr(s:go_stack_level) - str2nr(numPop)
  call go#def#Stack(newLevel + 1)
endfunction

function! go#def#Stack(...) abort
  if len(s:go_stack) == 0
    call go#util#EchoError("godef stack empty")
    return
  endif

  if !len(a:000)
    " Display interactive stack
    call go#def#StackUI()
    return
  else
    let jumpTarget = a:1
  endif

  if jumpTarget !~ '^\d\+$'
    if jumpTarget !~ '^\s*$'
      call go#util#EchoError("location must be a number")
    endif
    return
  endif

  let jumpTarget = str2nr(jumpTarget) - 1

  if jumpTarget >= 0 && jumpTarget < len(s:go_stack)
    let s:go_stack_level = jumpTarget
    let target = s:go_stack[s:go_stack_level]

    " jump
    if expand('%:p') != target["file"]
      if &modified
        exec 'hide edit' target["file"]
      else
        exec 'edit' target["file"]
      endif
    endif
    call cursor(target["line"], target["col"])
    normal! zz
  else
    call go#util#EchoError("invalid location. Try :GoDefStack to see the list of valid entries")
  endif
endfunction

function s:def_job(args)
  let callbacks = go#job#Spawn(a:args)

  let start_options = {
        \ 'callback': callbacks.callback,
        \ 'exit_cb': callbacks.exit_cb,
        \ 'close_cb': callbacks.close_cb,
        \ }

  if &modified
    let l:tmpname = tempname()
    call writefile(split(a:args.input, "\n"), l:tmpname, "b")
    let l:start_options.in_io = "file"
    let l:start_options.in_name = l:tmpname
  endif

  let job = job_start(a:args.cmd, start_options)
  return job
endfunction

" vim: sw=2 ts=2 et
