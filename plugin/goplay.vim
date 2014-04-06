if exists("g:go_loaded_goplay")
    finish
endif
let g:go_loaded_goplay = 1

if !exists("g:go_play_open_browser")
    let g:go_play_open_browser = 1
endif

function! s:GoPlay(count, line1, line2)
    if !executable('curl')
        echohl ErrorMsg | echomsg "vim-go: require 'curl' command" | echohl None
        return
    endif

    let content = join(getline(a:line1, a:line2), "\n")
    let share_file = tempname()
    call writefile(split(content, "\n"), share_file, "b")

    let command = "curl -s -X POST http://play.golang.org/share --data-binary '@".share_file."'"
    let snippet_id = system(command)

    " we can remove the temp file because it's now posted.
    call delete(share_file)

    if v:shell_error
        echo 'A error has occured. Run this command to see what the problem is:'
        echo command
        return
    endif

    let url = "http://play.golang.org/p/".snippet_id

    if "g:go_play_open_browser" != 0
        call s:open_browser(url)
    endif

    " TODO: copy url into a well known register, open in browser, etc...
    echo "Snippet uploaded: ".url
endfunction

command! -nargs=0 -range=% GoPlay call s:GoPlay(<count>, <line1>, <line2>)

function! s:get_visual_content()
    let save_regcont = @"
    let save_regtype = getregtype('"')
    silent! normal! gvy
    let content = @"
    call setreg('"', save_regcont, save_regtype)
    return content
endfunction

" modified version of
" http://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript
" another function that returns the content of visual selection, it's not used
" but might be useful in the future
function! s:get_visual_selection()
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]

    " check if the the visual mode is used before
    if lnum1 == 0  || lnum2 == 0  || col1 == 0  || col2 == 0
        return
    endif

    let lines = getline(lnum1, lnum2)
    let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][col1 - 1:]
    return join(lines, "\n")
endfunction

" following two functions are from: https://github.com/mattn/gist-vim 
" thanks  @mattn
function! s:get_browser_command()
  let go_play_browser_command = get(g:, 'go_play_browser_command', '')
  if go_play_browser_command == ''
    if has('win32') || has('win64')
      let go_play_browser_command = '!start rundll32 url.dll,FileProtocolHandler %URL%'
    elseif has('mac') || has('macunix') || has('gui_macvim') || system('uname') =~? '^darwin'
      let go_play_browser_command = 'open %URL%'
    elseif executable('xdg-open')
      let go_play_browser_command = 'xdg-open %URL%'
    elseif executable('firefox')
      let go_play_browser_command = 'firefox %URL% &'
    else
      let go_play_browser_command = ''
    endif
  endif
  return go_play_browser_command
endfunction

function! s:open_browser(url)
  let cmd = s:get_browser_command()
  if len(cmd) == 0
    redraw
    echohl WarningMsg
    echo "It seems that you don't have general web browser. Open URL below."
    echohl None
    echo a:url
    return
  endif
  if cmd =~ '^!'
    let cmd = substitute(cmd, '%URL%', '\=shellescape(a:url)', 'g')
    silent! exec cmd
  elseif cmd =~ '^:[A-Z]'
    let cmd = substitute(cmd, '%URL%', '\=a:url', 'g')
    exec cmd
  else
    let cmd = substitute(cmd, '%URL%', '\=shellescape(a:url)', 'g')
    call system(cmd)
  endif
endfunction


" vim:ts=4:sw=4:et
