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
        if exists('s:job')
            call job_status(s:job) "trigger exitHandler
            call job_stop(s:job)
            unlet s:job
        endif
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

        call go#util#EchoError("FAILED")

        let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
        let dir = getcwd()
        try
            execute cd self.dir
            let errors = go#tool#ParseErrors(self.combined)
            let errors = go#tool#FilterValids(errors)
        finally
            execute cd . fnameescape(dir)
        endtry

        if !len(errors)
            " failed to parse errors, output the original content
            call go#util#EchoError(join(self.combined, "\n"))
            return
        endif

        if self.winnr == winnr()
            let l:listtype = "locationlist"
            call go#list#Populate(l:listtype, errors)
            call go#list#Window(l:listtype, len(errors))
            if !empty(errors) && !self.bang
                call go#list#JumpToFirst(l:listtype)
            endif
        endif
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

" vim:ts=4:sw=4:et
