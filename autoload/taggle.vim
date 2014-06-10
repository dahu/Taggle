" Private data & functions {{{1

let s:default_taggle_delta = 60 * 5

if !exists('g:taggle_delta')
  let g:taggle_delta = s:default_taggle_delta
endif

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
  if &tags =~ '\./tags'
    return './tags'
  else
    return ''
  endif
endfunction
"}}}1

" Public interface {{{1
function! taggle#periodic_rebuild(time)
  let time = a:time
  let delta = s:taggle_delta()
  if (! exists('b:last_taggled')) || ((time - b:last_taggled) > delta)
    let b:last_taggled = time
    return taggle#rebuild('')
  endif
endfunction

function! taggle#rebuild(file)
  return taggle#ctags(a:file, '-R')
endfunction

function! taggle#append(file)
  return taggle#ctags(a:file, '--append ' . a:file)
endfunction

function! taggle#ctags(file, args)
  let file = fnameescape(a:file)
  let tagfile = s:find_tag_file(file)
  if tagfile != ''
    silent! call system('ctags -f ' . tagfile . ' ' . a:args)
  else
    echohl Warning
    echom 'No tags file found for: ' . file
    echohl None
  endif
endfunction
"}}}1
