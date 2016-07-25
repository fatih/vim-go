let s:go_imports_var = {
      \  'init':   'ctrlp#imports#init()',
      \  'exit':   'ctrlp#imports#exit()',
      \  'enter':  'ctrlp#imports#enter()',
      \  'accept': 'ctrlp#imports#accept',
      \  'lname':  'go imports',
      \  'sname':  'imports',
      \  'type':   'tabs',
      \}

if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:go_imports_var)
else
  let g:ctrlp_ext_vars = [s:go_imports_var]
endif

function! ctrlp#imports#init()
  cal s:enable_syntax()
  return s:imports
endfunction

function! ctrlp#imports#exit()
  unlet! s:imports
endfunction

function! ctrlp#imports#accept(mode, str)
  call ctrlp#exit()
  call go#import#SwitchImport(1, '', split(a:str, "\t", 1)[0], '')
endfunction

function! ctrlp#imports#enter()
  let s:imports = []

  let bin_path = go#path#CheckBinPath('go')
  if empty(bin_path)
    return
  endif

  " get a list of all available imports including package docs
  let command = printf("%s list -f \"{{.ImportPath}}\t{{.Doc}}\" ...", bin_path)

  let out = go#util#System(command)
  if go#util#ShellError() != 0
    call go#util#EchoError(out)
    return
  endif

  let data = map(split(out, "\n"), 'split(v:val, "\t", 1)')

  let max_len = 0
  for item in data
    if len(item[0])> max_len
      let max_len = len(item[0])
    endif
  endfor

  for item in data
    " paddings
    let space = " "
    for i in range(max_len - len(item[0]))
      let space .= " "
    endfor

    call add(s:imports, printf("%s\t\%s", item[0] . space, item[1]))
  endfor
  return
endfunc

function! s:enable_syntax()
	if !ctrlp#nosy()
		call ctrlp#hicheck('CtrlPTabExtra', 'Comment')
		syn match CtrlPTabExtra '\zs\t.*\ze$'
  endif
endfunction

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)

function! ctrlp#imports#cmd()
  return s:id
endfunction

" vim: sw=2 ts=2 et
