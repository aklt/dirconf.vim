"===============================================================================
" File:        dirconf.vim
" Description: Directory specific vim configuration
" Author:      Anders Thøgersen <anders [at] bladre.dk>
" License:     This program is free software. It comes without any warranty.
"===============================================================================
if &compatible || exists('g:loaded_dirconf')
  finish
endif
let g:loaded_dirconf = 'v0.3.0'
let s:keepcpo = &cpoptions
set cpoptions&vim

if !exists('g:dirconf_dir')
  let g:dirconf_dir = $HOME . '/.vim/dirconf'
endif

if !exists('g:dirconf_verbose')
  let g:dirconf_verbose = 0
endif

if !exists('g:dirconf_join')
  let g:dirconf_join = '#'
endif

if !exists('g:dirconf_parent_files')
  let g:dirconf_parent_files = ['.git/config']
endif

if !isdirectory(g:dirconf_dir) && exists('*mkdir')
  call mkdir(g:dirconf_dir, 'p', 0700)
  call s:Echo('dirconf.vim: created ' . g:dirconf_dir)
endif

fun! s:FindParentDirContainingOneOf(paths)
  let l:paths = a:paths
  if type(l:paths) != type([])
    let l:paths = [l:paths]
  endif
  let l:expandDir = '%:p:h'
  let l:nextdir = expand(l:expandDir)
  let l:dir = ''
  let l:path = ''
  while l:dir != l:nextdir && !filereadable(l:path)
    let l:dir = l:nextdir
    for l:file in l:paths
      let l:path = l:dir . '/' . l:file
      if filereadable(l:path)
        return l:dir
      end
    endfor
    let l:expandDir .= ':h'
    let l:nextdir = expand(l:expandDir)
  endwhile
endfun

fun! s:ShortDirName(dir)
  return g:dirconf_dir . '/' . substitute(substitute(
        \ a:dir, '^' . $HOME, 'HOME', ''), '/', g:dirconf_join, 'g')
endfun

fun! s:FuncName (dir)
  return 'func' . substitute(a:dir, '\W\+', '_', 'g')
endfun

fun! s:Echo(...)
  if g:dirconf_verbose
    echomsg join(a:000, ' ')
  endif
endfun

let g:dirconf_sourced = {}
let g:dirconf_eager = {}
let g:dirconf_current_func = ''

fun! s:Check()
  call s:Echo('dirconf.vim: Check')
  let l:dir = s:FindParentDirContainingOneOf(g:dirconf_parent_files)
  if !empty(l:dir)
    let l:pathName = s:ShortDirName(l:dir)
    let l:confFile = l:pathName . '.vim'
    let l:funcName = s:FuncName(l:dir)
    if has_key(g:dirconf_sourced, l:funcName)
      if g:dirconf_current_func != l:funcName ||
            \ (has_key(g:dirconf_eager, l:funcName) &&
            \  g:dirconf_eager[l:funcName] == 1)
        let g:dirconf_eager[l:funcName] = g:dirconf_sourced[l:funcName](l:dir, l:pathName, l:confFile)
        let g:dirconf_current_func = l:funcName
        call s:Echo('dirconf.vim: ran function ' . l:funcName)
      endif
      return
    endif
    if filereadable(l:confFile)
      " Magically wrap continuation lines
      let l:filecontents = split(
            \   substitute(
            \     join(readfile(l:confFile), "\n"),
            \   '\n\s*\\', ' ', 'g'),
            \ '\n')
      let l:fileFunction = [ 'fun! g:dirconf_sourced.' . l:funcName .
                         \   '(dir, name, file)' ] +
                         \ [ 'let _DC_CpoSave = &cpo', 'set cpo&vim' ] +
                         \ [ 'let b:did_ftplugin = 1' ] +
                         \ [ 'let reload_eagerly = 0' ] +
                         \   l:filecontents +
                         \ [ 'let &cpo = _DC_CpoSave' ] +
                         \ [ 'return reload_eagerly' ] +
                         \ [ 'endfun' ]
      " create function for this dir
      call s:Echo(join(l:fileFunction, '\n'))
      call execute(l:fileFunction)
      let g:dirconf_eager[l:funcName] =
            \ g:dirconf_sourced[l:funcName](l:dir, l:pathName, l:confFile)
      if g:dirconf_verbose
        call s:Echo('dirconf.vim: created ' .
              \ string(g:dirconf_sourced[l:funcName]))
      endif
    else
      if g:dirconf_verbose
        call s:Echo('dirconf.vim: not sourcing file ' . l:confFile)
      endif
    endif
  endif
endfun

augroup DirConf
  autocmd!
  autocmd BufReadPre * call <SID>Check()
augroup END

fun! s:EditDirConf(...)
  let l:editFiletype = 'vim'
  if a:0
    let l:editFiletype = a:000[0]
  endif
  let l:dir = s:FindParentDirContainingOneOf(g:dirconf_parent_files)
  if !empty(l:dir)
    let l:funcName = s:FuncName(l:dir)
    let l:dir = s:ShortDirName(l:dir)
    let l:dir .= '.' . l:editFiletype
    if l:editFiletype ==# 'vim' && has_key(g:dirconf_sourced, l:funcName)
      " Remove function so it will be sourced again
      call remove(g:dirconf_sourced, l:funcName)
    endif
    exe ':vsplit ' . escape(l:dir, '-#%' . g:dirconf_join)
  endif
endfun

" testing
if exists('g:dirconf_test') && g:dirconf_test
  command! -nargs=1 FindParentDirContainingOneOf 
        \ call s:FindParentDirContainingOneOf(<f-args>)
  command! -nargs=1 ShortDirName call s:ShortDirName(<f-args>)
  command! -nargs=1 FuncName call s:FuncName
  command! -nargs=0 Check call s:Check()
  command! -nargs=* EditDirConf call s:EditDirConf(<f-args>)
endif

fun! s:DirConfComplete(arglead, cmdline, cursorpos)
  let l:glob = a:arglead
  if !empty(l:glob)
    let l:glob = '*' . l:glob . '*'
  else
    let l:glob = '*'
  endif
  return map(globpath(g:dirconf_dir, l:glob, 0, 1), "substitute(v:val, '^.*#\\([^#]\\+\\)$', '\\1', '')")
endfun

command! -complete=customlist,s:DirConfComplete -nargs=? DirConf call <SID>EditDirConf(<f-args>)

let &cpoptions = s:keepcpo
unlet s:keepcpo
