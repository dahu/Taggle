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

augroup Taggle
  au!
  au BufRead      * call taggle#append(expand('%'))
  au InsertLeave  * call taggle#append(localtime())
  au CursorHold   * call taggle#periodic_rebuild(localtime())
  au BufWritePost * call taggle#append(expand('%'))
augroup END
