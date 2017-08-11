function! go#dep#Init() abort
  " Initialize GoDep
  call go#util#EchoProgress("Initializing GoDep")
  let out = go#util#System("dep init")
  call go#util#EchoProgress("GoDep Initialized")
endfunction

function! go#dep#Ensure(flag, package) abort
  " Ensure that if the options is to add a new package, the package was given
  if a:flag == "--add" && a:package == ""
    call s:Error("Package to add not provided")
    return
  endif

  " Run GoDep ensure to add/update/install dependencies
  call go#util#EchoProgress("Runnig dep ensure " . a:flag . " " . a:package)
  let out = go#util#System("dep ensure " . a:flag . " " . a:package)

  " If the option is to add a new package, autoimport it
  if a:package != ""
      call go#import#SwitchImport(1, "", a:package, "<bang>")
      return
  endif
endfunction
