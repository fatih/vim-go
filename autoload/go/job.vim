function! go#job#Spawn(bang, args)
    " autowrite is not enabled for jobs
    call go#cmd#autowrite()

    " modify GOPATH if needed
    let old_gopath = $GOPATH
    let $GOPATH = go#path#Detect()

    " execute go build in the files directory
    let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
    let dir = getcwd()
    let jobdir = fnameescape(expand("%:p:h"))
    execute cd . jobdir

    let opts = {
                \ 'dir': dir,
                \ 'bang': a:bang, 
                \ 'winnr': winnr(),
                \ 'combined' : [],
                \ }

    " add external callback to be called if async job is finished
    if has_key(a:args, 'external_cb')
        let opts.external_cb = a:args.external_cb
    endif

    func opts.callbackHandler(chan, msg) dict
        " contains both stderr and stdout
        call add(self.combined, a:msg)
    endfunc

    func opts.closeHandler(chan) dict
        if !exists('s:job')
        endif

        call job_status(s:job) "trigger exitHandler
        call job_stop(s:job)
        unlet s:job
    endfunc

    func opts.exitHandler(job, exit_status) dict
        if has_key(self, 'external_cb')
            call self.external_cb(a:job, a:exit_status, self.combined)
        endif

        if a:exit_status == 0
            call go#list#Clean(0)
            call go#list#Window(0)
            call go#util#EchoSuccess("SUCCESS")
            return
        endif

        call s:show_errors(self.bang, self.errs, self.dir, self.winnr)
    endfunc

    let s:job = job_start(a:args.cmd, {
                \	"callback": opts.callbackHandler,
                \	"exit_cb": opts.exitHandler,
                \	"close_cb": opts.closeHandler,
                \ })

    call job_status(s:job)
    execute cd . fnameescape(dir)

    " restore back GOPATH
    let $GOPATH = old_gopath
endfunction

function! go#job#Buffer(bang, args)
    " autowrite is not enabled for jobs
    call go#cmd#autowrite()

    " modify GOPATH if needed
    let old_gopath = $GOPATH
    let $GOPATH = go#path#Detect()

    " execute go build in the files directory
    let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
    let dir = getcwd()
    let jobdir = fnameescape(expand("%:p:h"))
    execute cd . jobdir

    let opts = {
                \ 'dir': dir,
                \ 'bang': a:bang, 
                \ 'winnr': winnr(),
                \ 'errs' : [],
                \ 'bufnr' : s:create_buffer(),
                \ }

    func opts.errorHandler(chan, msg) dict
        " contains stderr
        call add(self.errs, a:msg)
    endfunc

    func opts.closeHandler(chan) dict
        if !exists('s:job')
            return
        endif

        if exists("#BufWinLeave#<buffer>") 
            autocmd! BufWinLeave <buffer>
        endif

        call job_status(s:job) "trigger exitHandler
        call job_stop(s:job)
        unlet s:job
    endfunc

    func opts.exitHandler(job, exit_status) dict
        if a:exit_status == 0
            call go#list#Clean(0)
            call go#list#Window(0)
            call go#util#EchoSuccess("SUCCESS")
            return
        endif

        exe 'bdelete! '.self.bufnr

        call s:show_errors(self.bang, self.errs, self.dir, self.winnr)
    endfunc

    " NOTE(arslan): the job buffer first line still has an empty line, not
    " sure how to remove it
    let s:job = job_start(a:args.cmd, {
                \	"out_io": "buffer",
                \	"out_buf": opts.bufnr,
                \	"exit_cb": opts.exitHandler,
                \	"err_cb": opts.errorHandler,
                \	"close_cb": opts.closeHandler,
                \ })

    call job_status(s:job)
    execute cd . fnameescape(dir)


    autocmd BufWinLeave <buffer> call opts.closeHandler()

    " restore back GOPATH
    let $GOPATH = old_gopath
endfunction

function! s:show_errors(bang, errs, dir, winnr)
    call go#util#EchoError("FAILED")

    let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
    let dir = getcwd()
    try
        execute cd a:dir
        let errors = go#tool#ParseErrors(a:errs)
        let errors = go#tool#FilterValids(errors)
    finally
        execute cd . fnameescape(dir)
    endtry

    if !len(errors)
        " failed to parse errors, output the original content
        call go#util#EchoError(a:errs[0])
        return
    endif

    if a:winnr == winnr()
        let l:listtype = "locationlist"
        call go#list#Populate(l:listtype, errors)
        call go#list#Window(l:listtype, len(errors))
        if !empty(errors) && !a:bang
            call go#list#JumpToFirst(l:listtype)
        endif
    endif
endfunction

function! s:create_buffer()
    execute 'new __go_job__'
    let l:buf_nr = bufnr('%')

    setlocal filetype=gojob
    setlocal bufhidden=delete
    setlocal buftype=nofile
    setlocal winfixheight
    setlocal noswapfile
    setlocal nobuflisted
    setlocal nocursorline
    setlocal nocursorcolumn

    " close easily with <esc> or enter
    noremap <buffer> <silent> <CR> :<C-U>close<CR>
    noremap <buffer> <silent> <Esc> :<C-U>close<CR>

    return l:buf_nr
endfunction


" vim:ts=4:sw=4:et
