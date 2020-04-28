" -- gorename
command! -nargs=? -complete=customlist,go#rename#Complete GoRename call go#rename#Rename(<bang>0, <f-args>)

" -- guru
command! -nargs=* -complete=customlist,go#package#Complete GoGuruScope call go#guru#Scope(<f-args>)
command! -range=% -bar GoImplements call go#implements#Implements(<count>)
command! -range=% -bar GoPointsTo call go#guru#PointsTo(<count>)
command! -range=% -bar GoWhicherrs call go#guru#Whicherrs(<count>)
command! -range=% -bar GoCallees call go#guru#Callees(<count>)
command! -range=% -bar GoDescribe call go#guru#Describe(<count>)
command! -range=% -bar GoCallers call go#guru#Callers(<count>)
command! -range=% -bar GoCallstack call go#guru#Callstack(<count>)
command! -range=% -bar GoFreevars call go#guru#Freevars(<count>)
command! -range=% -bar GoChannelPeers call go#guru#ChannelPeers(<count>)
command! -range=% -bar GoReferrers call go#referrers#Referrers(<count>)

command! -range=0 -bar GoSameIds call go#guru#SameIds(1)
command! -range=0 -bar GoSameIdsClear call go#guru#ClearSameIds()
command! -range=0 -bar GoSameIdsToggle call go#guru#ToggleSameIds()
command! -range=0 -bar GoSameIdsAutoToggle call go#guru#AutoToggleSameIds()

" -- tags
command! -nargs=* -range GoAddTags call go#tags#Add(<line1>, <line2>, <count>, <f-args>)
command! -nargs=* -range GoRemoveTags call go#tags#Remove(<line1>, <line2>, <count>, <f-args>)

" -- mod
command! -nargs=0 -range -bar GoModFmt call go#mod#Format()

" -- tool
command! -nargs=* -complete=customlist,go#tool#ValidFiles -bar GoFiles echo go#tool#Files(<f-args>)
command! -nargs=0 -bar GoDeps echo go#tool#Deps()
command! -nargs=0 -bar GoInfo call go#tool#Info(1)
command! -nargs=0 -bar GoAutoTypeInfoToggle call go#complete#ToggleAutoTypeInfo()

" -- cmd
command! -nargs=* -bang GoBuild call go#cmd#Build(<bang>0,<f-args>)
command! -nargs=? -bang GoBuildTags call go#cmd#BuildTags(<bang>0, <f-args>)
command! -nargs=* -bang GoGenerate call go#cmd#Generate(<bang>0,<f-args>)
command! -nargs=* -bang -complete=file GoRun call go#cmd#Run(<bang>0,<f-args>)
command! -nargs=* -bang GoInstall call go#cmd#Install(<bang>0, <f-args>)

" -- test
command! -nargs=* -bang GoTest call go#test#Test(<bang>0, 0, <f-args>)
command! -nargs=* -bang GoTestFunc call go#test#Func(<bang>0, <f-args>)
command! -nargs=* -bang GoTestCompile call go#test#Test(<bang>0, 1, <f-args>)

" -- cover
command! -nargs=* -bang GoCoverage call go#coverage#Buffer(<bang>0, <f-args>)
command! -nargs=* -bang GoCoverageClear call go#coverage#Clear()
command! -nargs=* -bang GoCoverageToggle call go#coverage#BufferToggle(<bang>0, <f-args>)
command! -nargs=* -bang GoCoverageBrowser call go#coverage#Browser(<bang>0, <f-args>)

" -- play
command! -nargs=0 -range=% -bar GoPlay call go#play#Share(<count>, <line1>, <line2>)

" -- def
command! -nargs=* -range GoDef :call go#def#Jump('', 0)
command! -nargs=* -range GoDefType :call go#def#Jump('', 1)
command! -nargs=? -bar GoDefPop :call go#def#StackPop(<f-args>)
command! -nargs=? -bar GoDefStack :call go#def#Stack(<f-args>)
command! -nargs=? -bar GoDefStackClear :call go#def#StackClear(<f-args>)

" -- doc
command! -nargs=* -range -complete=customlist,go#package#Complete -bar GoDoc call go#doc#Open('new', 'split', <f-args>)
command! -nargs=* -range -complete=customlist,go#package#Complete -bar GoDocBrowser call go#doc#OpenBrowser(<f-args>)

" -- fmt
command! -nargs=0 -bar GoFmt call go#fmt#Format(-1)
command! -nargs=0 -bar GoFmtAutoSaveToggle call go#fmt#ToggleFmtAutoSave()
command! -nargs=0 -bar GoImports call go#fmt#Format(1)

" -- asmfmt
command! -nargs=0 -bar GoAsmFmtAutoSaveToggle call go#asmfmt#ToggleAsmFmtAutoSave()

" -- import
command! -nargs=? -complete=customlist,go#package#Complete -bar GoDrop call go#import#SwitchImport(0, '', <f-args>, '')
command! -nargs=1 -bang -complete=customlist,go#package#Complete -bar GoImport call go#import#SwitchImport(1, '', <f-args>, '<bang>')
command! -nargs=* -bang -complete=customlist,go#package#Complete -bar GoImportAs call go#import#SwitchImport(1, <f-args>, '<bang>')

" -- linters
command! -nargs=* -bang GoMetaLinter call go#lint#Gometa(<bang>0, 0, <f-args>)
command! -nargs=0 -bar GoMetaLinterAutoSaveToggle call go#lint#ToggleMetaLinterAutoSave()
command! -nargs=* -bang GoLint call go#lint#Golint(<bang>0, <f-args>)
command! -nargs=* -bang GoVet call go#lint#Vet(<bang>0, <f-args>)
command! -nargs=* -bang -complete=customlist,go#package#Complete GoErrCheck call go#lint#Errcheck(<bang>0, <f-args>)

" -- alternate
command! -bang -bar GoAlternate call go#alternate#Switch(<bang>0, '')

" -- decls
command! -nargs=? -bar -complete=file GoDecls call go#decls#Decls(0, <q-args>)
command! -nargs=? -bar -complete=dir GoDeclsDir call go#decls#Decls(1, <q-args>)

" -- impl
command! -nargs=* -bar -complete=customlist,go#impl#Complete GoImpl call go#impl#Impl(<f-args>)

" -- template
command! -nargs=0 -bar GoTemplateAutoCreateToggle call go#template#ToggleAutoCreate()

" -- keyify
command! -nargs=0 -bar GoKeyify call go#keyify#Keyify()

" -- fillstruct
command! -nargs=0 -bar GoFillStruct call go#fillstruct#FillStruct()

" -- debug
if !exists(':GoDebugStart')
  command! -nargs=* -complete=customlist,go#package#Complete GoDebugStart call go#debug#Start(0, <f-args>)
  command! -nargs=* -complete=customlist,go#package#Complete GoDebugTest  call go#debug#Start(1, <f-args>)
  command! -nargs=? GoDebugBreakpoint call go#debug#Breakpoint(<f-args>)
endif

" -- issue
command! -nargs=0 -bar GoReportGitHubIssue call go#issue#New()

" -- iferr
command! -nargs=0 -bar GoIfErr call go#iferr#Generate()

" -- lsp
command! -nargs=+ -complete=dir GoAddWorkspace call go#lsp#AddWorkspaceDirectory(<f-args>)
command! -nargs=0 -bar GoLSPDebugBrowser call go#lsp#DebugBrowser()
command! -nargs=* -bang GoDiagnostics call go#lint#Diagnostics(<bang>0, <f-args>)

" -- term
command! -bar GoToggleTermCloseOnExit call go#term#ToggleCloseOnExit()

" vim: sw=2 ts=2 et
