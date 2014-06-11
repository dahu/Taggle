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
  let tagfile = s:find_tag_file(file)
  if (tagfile != '') && (getcwd() != $HOME)
    silent! call system('ctags -f ' . tagfile . ' ' . a:args . ' &')
  endif
endfunction

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
