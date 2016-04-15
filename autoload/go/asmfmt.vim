" asmfmt.vim: Vim command to format Go asm files with asmfmt
" (github.com/klauspost/asmfmt).
"
" This filetype plugin adds new commands for asm buffers:
"
"   :Fmt
"
"       Filter the current asm buffer through asmfmt.
"       It tries to preserve cursor position and avoids
"       replacing the buffer with stderr output.
"
" Options:
"
"   g:go_asmfmt_autosave [default=1]
"
"       Flag to automatically call :Fmt when file is saved.

let s:got_fmt_error = 0

" This is a trimmed-down version of the logic in fmt.vim.

function! go#asmfmt#Format()
  " Save state.
  let l:curw = winsaveview()

  " Write the current buffer to a tempfile.
  let l:tmpname = tempname()
  call writefile(getline(1, '$'), l:tmpname)

  " Run asmfmt.
  let path = go#path#CheckBinPath("asmfmt")
  if empty(path)
    return
  endif
  let out = go#util#system(path . ' -w ' . l:tmpname)

  " If there's no error, replace the current file with the output.
  if go#util#shell_error() != 0
    " Remove undo point caused by BufWritePre.
    try | silent undojoin | catch | endtry

    " Replace the current file with the temp file; then reload the buffer.
    let old_fileformat = &fileformat
    call rename(l:tmpname, expand('%'))
    silent edit!
    let &fileformat = old_fileformat
    let &syntax = &syntax
  endif

  " Restore the cursor/window positions.
  call winrestview(l:curw)
endfunction
