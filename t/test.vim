describe 'go#coverlay#Coverlay'
    before
        new
	let g:curdir = expand('<sfile>:p:h') . '/'
	let g:srcpath = 't/fixtures/src/'
	let g:sample = 'pkg1/sample.go'
	let g:sampleabs = g:curdir . g:srcpath . 'pkg1/sample.go'
	let g:samplecover = g:curdir . g:srcpath . 'pkg1/sample.out'
	let g:go_gopath = g:curdir . 't/fixtures'
	execute "badd " . g:srcpath . g:sample
	execute "buffer " . bufnr("$")
    end
    after
	execute "bprev"
	execute "bdelete " . g:srcpath . g:sample
        close!
    end

    it 'puts match to the list'
        call go#coverlay#Coverlay()
        Expect len(go#coverlay#matches()) == 5
        call go#coverlay#Clearlay()
        Expect len(go#coverlay#matches()) == 0

        call go#coverlay#Coverlay()
        Expect len(go#coverlay#matches()) == 5
        call go#coverlay#Clearlay()
        Expect len(go#coverlay#matches()) == 0
    end
end

describe 'go#coverlay#isopenedon'
    before
        new
	let g:curdir = expand('<sfile>:p:h') . '/'
	let g:srcpath = 't/fixtures/src/'
	let g:sample = 'pkg1/sample.go'
	let g:sampleabs = g:curdir . g:srcpath . 'pkg1/sample.go'
	let g:go_gopath = g:curdir . 't/fixtures'
	execute "badd " . g:srcpath . g:sample
    end
    after
	execute "bdelete " . g:srcpath . g:sample
        close!
    end

    it 'returns 1 if FILE is opened at BUFNR'
        Expect go#coverlay#isopenedon('_' . g:sampleabs, bufnr(g:sampleabs)) == 1
        Expect go#coverlay#isopenedon(g:sample, bufnr(g:sampleabs)) == 1
    end

    it 'returns 0 if FILE is not opened at BUFNR'
        Expect go#coverlay#isopenedon('_' . g:sampleabs, 42) == 0
        Expect go#coverlay#isopenedon(g:sample, 42) == 0
    end

    it 'returns 0 if FILE is not exists'
        Expect go#coverlay#isopenedon('_' . g:curdir . g:srcpath . 'pkg1/NOTEXISTS', bufnr(g:sampleabs)) == 0
        Expect go#coverlay#isopenedon('pkg1/NOTEXISTS.go', bufnr(g:sampleabs)) == 0
    end
end

describe 'go#coverlay#parsegocoverline'
    it 'parses a go cover output line and returns as dict'
        let d = {'file': 'f',"startline": "1", "startcol": "2", "endline": "3", "endcol": "4", "numstmt": "5", "cnt": "6"}
        " file:startline.col,endline.col numstmt count
        Expect go#coverlay#parsegocoverline("f:1.2,3.4 5 6") == d
    end
end

describe 'go#coverlay#genmatch'
    it 'generate mark pattern from cover data'
        let d = {'file': 'f',"startline": "1", "startcol": "2", "endline": "3", "endcol": "4", "numstmt": "5", "cnt": "6"}
        Expect go#coverlay#genmatch(d) == {'group': 'covered', "pattern": '\%>1l\_^\s\+\%<3l\|\%1l\_^\s\+\|\%3l\_^\s\+\(\}$\)\@!', "priority": 6}
        let d = {'file': 'f',"startline": "1", "startcol": "2", "endline": "3", "endcol": "4", "numstmt": "5", "cnt": "0"}
        Expect go#coverlay#genmatch(d) == {'group': 'uncover', "pattern": '\%>1l\_^\s\+\%<3l\|\%1l\_^\s\+\|\%3l\_^\s\+\(\}$\)\@!', "priority": 5}
    end
end
