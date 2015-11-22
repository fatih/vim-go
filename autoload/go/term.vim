function! go#term#vsplit()
  execute 'vertical new'
	" setlocal filetype=vimgo
	" setlocal bufhidden=delete
	" setlocal buftype=nofile
	" setlocal noswapfile
	" setlocal nobuflisted
	" setlocal winfixheight
	setlocal cursorline " make it easy to distinguish
	" setlocal nomodifiable
  nnoremap <buffer> <C-d> :<C-u>close<CR>
endfunction

function! go#term#new(cmd)
  let id = termopen(a:cmd)
	startinsert
endfunction

function! go#term#kill()
endfunction

function! go#term#close()
endfunction

function! go#term#clear()
endfunction
