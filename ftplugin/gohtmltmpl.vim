if exists("b:did_ftplugin")
  finish
endif

runtime! ftplugin/html.vim

if exists('loaded_matchit')
  "let b:match_words .= ','
  "/\%({{\s*\)\<\%(if\|block\|define\|range\|with\)\>\%([^}]*}}\)\@=
  let b:match_words = ''
  let b:match_words .= '\%({{\s*\)\@!'                           " {{ followed by 0 or more spaces, zero-width.
  let b:match_words .= '\<\%(if\|block\|define\|range\|with\)\>' " if/block/define/range/with keywords.
  let b:match_words .= '\%([^}]*}}\)\@='                         " Any content until }}, zero-width.


	":let s:notend = '\%(\<end\s\+\)\@<!'
	":let b:match_words = s:notend . '\<if\>:\<end\s\+if\>'

  "let b:match_words .= ':'
  "let b:match_words .= '\%({{\s*\)\@!'                        " {{ followed by 0 or more spaces, zero-width.
  "let b:match_words .= '\<else'                                 " else keyword.
  "let b:match_words .= '\%(\s*if\)\?\>'                         " optional if for 'else if'
  "let b:match_words .= '\%([^}]*}}\)\@='                      " Any content until }}, zero width

  let b:match_words .= ':'
  let b:match_words .= '\%({{\s*\)\@!\<end\>\%(\s*}}\)\@='        " Same as above with s/else/end/
endif

" vim: sw=2 ts=2 et
