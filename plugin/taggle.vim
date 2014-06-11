" Vim global plugin for keeping a project's tags up to date while editing
" Maintainer:	Barry Arthur <barry.arthur@gmail.com>
" Version:	0.1
" Description:	Automatic tags file tickler frequently using --append and
" 		periodically doing full rebuilds.
" Last Change:	2014-06-11
" License:	Vim License (see :help license)
" Location:	plugin/taggle.vim
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

if exists("g:loaded_taggle")
      \ || v:version < 700
      \ || &compatible
  let &cpo = s:save_cpo
  finish
endif
let g:loaded_taggle = 1

" Options: {{{1

if !exists('g:taggle_delta')
  let g:taggle_delta = taggle#default_taggle_delta
endif


" Public Interface: {{{1
function! Taggle(...)
  if a:0
    let t = type(a:1)
    if t == type(0)
      " a localtime() value used for delta comparison
      return taggle#periodic_rebuild(a:1)
    elseif t == type('')
      if a:1 == ''
        " rebuild all tags
        return taggle#rebuild(expand('%'))
      else
        if ! filereadable(a:1)
          throw 'File not found: ' . a:1
        endif
        " ctags --append this-file
        return taggle#append(a:1)
      endif
    else
      throw 'Unexpected type: ' . t
    endif
  endif
endfunction

" Autocommands

augroup Taggle
  au!
  au BufRead      * call taggle#append(expand('%'))
  au InsertLeave  * call taggle#append(localtime())
  au CursorHold   * call taggle#periodic_rebuild(localtime())
  au BufWritePost * call taggle#append(expand('%'))
augroup END


" Teardown: {{{1
" reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
