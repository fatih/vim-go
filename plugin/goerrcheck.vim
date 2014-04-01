if exists("g:go_loaded_errcheck") 
  finish
endif
let g:go_loaded_errcheck = 1

command! GoErrCheck call s:ErrCheck()

function! s:ErrCheck() abort
  let out = system(g:go_errcheck_bin . ' ' . shellescape(expand('%:p:h')))
  if v:shell_error
		let errors = []
		for line in split(out, '\n')
				let mx = '^\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)'
				let tokens = matchlist(line, mx)

				if !empty(tokens)
						call add(errors, {"filename": tokens[1],
									\"lnum": tokens[2],
									\"col": tokens[3],
									\"text": tokens[4]})
				endif
		endfor
		if empty(errors)
				% | " Couldn't detect error format, output errors
		endif
		if !empty(errors)
				call setqflist(errors, 'r')
		endif
		echohl Error | echomsg "GoErrCheck returned error" | echohl None
  else
    call setqflist([])
  endif
  cwindow
endfunction

