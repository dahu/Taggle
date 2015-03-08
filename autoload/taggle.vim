" Vim library for keeping a project's tags up to date while editing
" Maintainer:	Barry Arthur <barry.arthur@gmail.com>
" Version:	0.1
" Description:	Automatic tags file tickler frequently using --append and
" 		periodically doing full rebuilds.
" Last Change:	2014-06-11
" License:	Vim License (see :help license)
" Location:	autoload/taggle.vim
" Website:	https://github.com/dahu/taggle
"
" See taggle.txt for help.  This can be accessed by doing:
"
" Taggle
"
" :helptags ~/.vim/doc
" :help taggle

" Vimscript Setup: {{{1
" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

if exists("g:loaded_lib_taggle")
      \ || v:version < 700
      \ || &compatible
  let &cpo = s:save_cpo
  finish
endif
let g:loaded_lib_taggle = 1

" Vim Script Information Function: {{{1
function! taggle#info()
  let info = {}
  let info.name = 'taggle'
  let info.version = 1.0
  let info.description = 'auto-regenerate tag files'
  return info
endfunction

" Private Functions: {{{1

let taggle#default_taggle_delta = 60 * 5

function! s:taggle_delta()
  if exists('b:taggle_delta')
    return b:taggle_delta
  elseif exists('w:taggle_delta')
    return w:taggle_delta
  elseif exists('t:taggle_delta')
    return t:taggle_delta
  else
    return g:taggle_delta
  endif
endfunction

function! s:find_tag_file(file)
  let file = escape(a:file, '/')
  let oldloclist = getloclist(0)
  call setloclist(0, [])
  for tf in split(&tags, '\\\@<!,')
    " the 1 before lvimgrep limits the search to that number of hits
    " (optimisation)
    exe 'silent! 1lvimgrep /' . file . '/j ' . tf
    let loclist = getloclist(0)
    if (len(loclist) > 0) && (loclist[0].text !~ '^grep:')
      call setloclist(0, oldloclist)
      return tf
    endif
  endfor
  call setloclist(0, oldloclist)
  " If we didn't find a tags file containing the filename we're looking for
  " but there is a tags file in the current directory, use it.
  if (&tags =~ '\./tags') && (filereadable('\./tags'))
    return './tags'
  else
    return ''
  endif
endfunction

" Library Interface: {{{1

function! taggle#periodic_rebuild(time)
  let time = a:time
  let delta = s:taggle_delta()
  if (! exists('b:last_taggled')) || ((time - b:last_taggled) > delta)
    let b:last_taggled = time
    return taggle#rebuild()
  endif
endfunction

function! taggle#rebuild()
  return taggle#ctags(expand('%'), '-R')
endfunction

function! taggle#append(file)
  return taggle#ctags(a:file, '--append ' . a:file)
endfunction

function! taggle#ctags(file, args)
  let file = fnameescape(a:file)
  " find_tag_file() uses the location-list which interferes with other
  " plugins also using the location-list (like Grope). This seems to be
  " a bug in Vim itself because the problem causes a SIGSEGV.
  " Workaround: default to ./tags only
  " let tagfile = s:find_tag_file(file)
  if filereadable('./tags')
    let tagfile = './tags'
  else
    return
  endif
  if (tagfile != '') && (getcwd() != $HOME)
    silent! call system('ctags -f ' . tagfile . ' ' . a:args . ' &')
  endif
  call taggle#hitags(a:file)
endfunction

" Tag highlight groups
" default colours based on https://github.com/romainl/Apprentice
try | silent hi Taggle_  | catch /^Vim\%((\a\+)\)\=:E411/ | hi Taggle_  cterm=underline gui=underline | endtry
try | silent hi Taggle_a | catch /^Vim\%((\a\+)\)\=:E411/ | hi Taggle_a ctermbg=208 ctermfg=238 guibg=#ff8700 guifg=#444444 | endtry
try | silent hi Taggle_c | catch /^Vim\%((\a\+)\)\=:E411/ | hi Taggle_c ctermbg=229 ctermfg=238 guibg=#ffffaf guifg=#444444 | endtry
try | silent hi Taggle_f | catch /^Vim\%((\a\+)\)\=:E411/ | hi Taggle_f ctermbg=66  ctermfg=238 guibg=#5f8787 guifg=#bcbcbc | endtry
try | silent hi Taggle_m | catch /^Vim\%((\a\+)\)\=:E411/ | hi Taggle_m ctermbg=73  ctermfg=238 guibg=#5fafaf guifg=#444444 | endtry
try | silent hi Taggle_v | catch /^Vim\%((\a\+)\)\=:E411/ | hi Taggle_v ctermbg=110 ctermfg=238 guibg=#8fafd7 guifg=#444444 | endtry

if !exists('g:taggle_highlight')
  let g:taggle_highlight = 0
endif

if !exists('g:taggle_highlight_multi_coloured')
  let g:taggle_highlight_multi_coloured = 0
endif

if !exists('g:taggle_highlight_skip_file_patterns')
  let g:taggle_highlight_skip_file_patterns = ['test']
endif

let s:tag_pat = '^\(\S\+\).*\(\S\+\)$'
let s:syn_rep = '\="syn match Taggle_" . '
      \ . (g:taggle_highlight_multi_coloured ? 'submatch(2)' : '""')
      \ . ' . " \/" . expand(submatch(1), "/") . "\/ "'
      \ . ' . " containedin=ALLBUT,.*string.*,.*comment.*"'

let s:highlight_groups = []

function! taggle#hitags(file)
  if g:taggle_highlight
    let file = fnameescape(a:file)
    let tagfile = s:find_tag_file(file)
    if tagfile != ''
      let tags = readfile(tagfile)
      for t in tags
        if t =~ '^\!'
          continue
        endif
        let fname = matchstr(t, '^\S\+\t\zs\S\+\ze\t')
        if len(filter(map(copy(g:taggle_highlight_skip_file_patterns),
              \ 'fname =~ v:val'), 'v:val == 1')) == 0
          let type = 'Taggle_' . (g:taggle_highlight_multi_coloured ? matchstr(t, '\S\+$') : '')
          call add(s:highlight_groups, type)
          let syn_exp = substitute(t, s:tag_pat, s:syn_rep, '')
          exe syn_exp
        endif
      endfor
      let s:highlight_groups = uniq(sort(s:highlight_groups))
    endif
  else
    call taggle#hiclear()
  endif
endfunction

function! taggle#hiclear()
  for t in s:highlight_groups
    exe 'hi clear ' . t
  endfor
  let s:highlight_groups = []
endfunction

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
