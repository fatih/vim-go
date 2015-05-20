" install necessary Go tools
if exists("g:go_loaded_install")
    finish
endif
let g:go_loaded_install = 1

" initial_go_path is used to store the initial GOPATH that was set when Vim
" was started. It's used with :GoPathClear to restore the GOPATH when the user
" changed it explicitly via :GoPath. Initially it's empty. It's being set when
" :GoPath is used
let s:initial_go_path = ""

" these packages are used by vim-go and can be automatically installed if
" needed by the user with GoInstallBinaries
let s:packages = [
            \ "github.com/nsf/gocode",
            \ "golang.org/x/tools/cmd/goimports",
            \ "github.com/rogpeppe/godef",
            \ "golang.org/x/tools/cmd/oracle",
            \ "golang.org/x/tools/cmd/gorename",
            \ "github.com/golang/lint/golint",
            \ "github.com/kisielk/errcheck",
            \ "github.com/jstemmer/gotags",
            \ ]

" These commands are available on any filetypes
command! GoInstallBinaries call s:GoInstallBinaries(-1)
command! GoUpdateBinaries call s:GoInstallBinaries(1)
command! -nargs=? -complete=dir GoPath call s:GoPath(<f-args>)
command! GoPathClear call s:GoPathClear()


" LineEnding returns the correct line ending, based on the current fileformat
function! LineEnding()
    if &fileformat == 'dos'
        return "\r\n"
    elseif &fileformat == 'mac'
        return "\r"
    endif

    return "\n"
endfunction

" IsWin returns 1 if current OS is Windows or 0 otherwise
function! IsWin()
    let win = ['win16', 'win32', 'win32unix', 'win64', 'win95']
    for w in win
        if (has(w))
            return 1
        endif
    endfor

    return 0
endfunction

" PathSep returns the appropriate OS specific path separator.
function! PathSep()
    if IsWin()
        return '\'
    endif
    return '/'
endfunction

" PathListSep returns the appropriate OS specific path list separator.
function! PathListSep()
    if IsWin()
        return ";"
    endif
    return ":"
endfunction


" DefaultGoPath returns the default GOPATH.  If there is only one GOPATH it
" returns that, otherwise it returns the first one.
function! DefaultGoPath()
    let go_paths = split($GOPATH, PathListSep())

    if len(go_paths) == 1
        return $GOPATH
    endif

    return go_paths[0]
endfunction

" GetBinPath returns the binary path of installed go tools
function! GetBinPath()
    let bin_path = ""

    " check if our global custom path is set, if not check if $GOBIN is set so
    " we can use it, otherwise use $GOPATH + '/bin'
    if exists("g:go_bin_path")
        let bin_path = g:go_bin_path
    elseif $GOBIN != ""
        let bin_path = $GOBIN
    elseif $GOPATH != ""
        let bin_path = expand(DefaultGoPath() . "/bin/")
    else
        " could not find anything
    endif

    return bin_path
endfunction


" GoPath sets or returns the current GOPATH. If no arguments are passed it
" echoes the current GOPATH, if an argument is passed it replaces the current
" GOPATH with it.
function! s:GoPath(...)
    " we have an argument, replace GOPATH
    if len(a:000)
        echon "vim-go: " | echohl Function | echon "GOPATH changed to ". a:1 | echohl None
        let s:initial_go_path = $GOPATH
        let $GOPATH = a:1
        return
    endif

    echo DetectGoPath()
endfunction

" GoPathClear clears the current manually set GOPATH and restores it to the
" initial GOPATH, which was set when Vim was started.
function! s:GoPathClear()
    if !empty(s:initial_go_path)
        let $GOPATH = s:initial_go_path
        let s:initial_go_path = ""
    endif

    echon "vim-go: " | echohl Function | echon "GOPATH restored to ". $GOPATH | echohl None
endfunction


" callWithGopath calls the given function with the given GOPATH context. After
" the function call GOPATH is restored to the previous GOPATH.
function! s:callWithGopath(fn, gopath)
    let old_gopath = $GOPATH
    let $GOPATH = a:gopath
    call a:fn()
    let $GOPATH = old_gopath
endfunction

" DetectGoPath returns the current GOPATH. If a package manager is used, such
" as Godeps or something like gb (not supported yet), it will modify the
" GOPATH so those directories take precedence over the current GOPATH.
function! DetectGoPath()
    let gopath = $GOPATH

    " if gopath is set manually, always return it, because this is something
    " the user explicitly wants
    if !empty(s:initial_go_path)
        return s:initial_go_path
    endif

    " don't lookup for godeps if autodetect is disabled.
    if !get(g:, "go_autodetect_gopath", 1)
        return gopath
    endif

    let current_dir = fnameescape(expand('%:p:h'))

    " TODO(arslan): this should be changed so folders or files should be
    " fetched from a customizable list. The user should define any new package
    " management tool by it's own.
    "
    " Godeps
    let godeps_root = finddir("Godeps", current_dir .";")
    if !empty(godeps_root)
        let godeps_path = join([fnamemodify(godeps_root, ':p:h:h'), "Godeps", "_workspace" ], PathSep())
        let gopath =  godeps_path . PathListSep() . gopath
    endif

    return gopath
endfunction

" GoInstallBinaries downloads and install all necessary binaries stated in the
" packages variable. It uses by default $GOBIN or $GOPATH/bin as the binary
" target install directory. GoInstallBinaries doesn't install binaries if they
" exist, to update current binaries pass 1 to the argument.
function! s:GoInstallBinaries(updateBinaries)
    if $GOPATH == ""
        echohl Error
        echomsg "vim.go: $GOPATH is not set"
        echohl None
        return
    endif

    let err = s:CheckBinaries()
    if err != 0
        return
    endif

    let go_bin_path = GetBinPath()

    " change $GOBIN so go get can automatically install to it
    let $GOBIN = go_bin_path

    " old_path is used to restore users own path
    let old_path = $PATH

    " vim's executable path is looking in PATH so add our go_bin path to it
    let $PATH = $PATH . PathListSep() .go_bin_path

    " when shellslash is set on MS-* systems, shellescape puts single quotes
    " around the output string. cmd on Windows does not handle single quotes
    " correctly. Unsetting shellslash forces shellescape to use double quotes
    " instead.
    let resetshellslash = 0
    if has('win32') && &shellslash
        let resetshellslash = 1
        set noshellslash
    endif

    for pkg in s:packages
        let basename = fnamemodify(pkg, ":t")
        let binname = "go_" . basename . "_bin"

        let bin = basename
        if exists("g:{binname}")
            let bin = g:{binname}
        endif

        if !executable(bin) || a:updateBinaries == 1
            if a:updateBinaries == 1
                echo "vim-go: Updating ". basename .". Reinstalling ". pkg . " to folder " . go_bin_path
            else
                echo "vim-go: ". basename ." not found. Installing ". pkg . " to folder " . go_bin_path
            endif

            let out = system("go get -u -v ".shellescape(pkg))
            if v:shell_error
                echo "Error installing ". pkg . ": " . out
            endif
        endif
    endfor

    " restore back!
    let $PATH = old_path
    if resetshellslash
        set shellslash
    endif
endfunction

" CheckBinaries checks if the necessary binaries to install the Go tool
" commands are available.
function! s:CheckBinaries()
    if !executable('go')
        echohl Error | echomsg "vim-go: go executable not found." | echohl None
        return -1
    endif

    if !executable('git')
        echohl Error | echomsg "vim-go: git executable not found." | echohl None
        return -1
    endif
endfunction

" Autocommands
" ============================================================================

augroup vim-go
    autocmd!

    " GoInfo automatic update
    if get(g:, "go_auto_type_info", 0)
        autocmd CursorHold *.go nested call go#complete#Info()
    endif

    " code formatting on save
    if get(g:, "go_fmt_autosave", 1)
        autocmd BufWritePre *.go call go#fmt#Format(-1)
    endif

augroup END


" vim:ts=4:sw=4:et
