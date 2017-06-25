"===============================================================================
" File:        dirconf.vim
" Description: Directory specific vim configuration
" Author:      Anders Thøgersen <anders [at] bladre.dk>
" License:     This program is free software. It comes without any warranty.
"===============================================================================
if &cp || exists('g:loaded_dirconf')
  finish
endif
let g:loaded_dirconf = 'v0.2.0'
let s:keepcpo = &cpo
set cpo&vim

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
  let paths = a:paths
  if type(paths) != type([])
    let paths = [paths]
  endif
  let expandDir = '%:p:h'
  let nextdir = expand(expandDir)
  let dir = ''
  let path = ''
  while dir != nextdir && !filereadable(path)
    let dir = nextdir
    for file in paths
      let path = dir . '/' . file
      if filereadable(path)
        return dir
      end
    endfor
    let expandDir .= ':h'
    let nextdir = expand(expandDir)
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
  let dir = s:FindParentDirContainingOneOf(g:dirconf_parent_files)
  if !empty(dir)
    let pathName = s:ShortDirName(dir)
    let confFile = pathName . '.vim'
    let funcName = s:FuncName(dir)
    if has_key(g:dirconf_sourced, funcName)
      if g:dirconf_current_func != funcName ||
            \ (has_key(g:dirconf_eager, funcName) && g:dirconf_eager[funcName])
        call g:dirconf_sourced[funcName](dir, pathName, confFile)
        let g:dirconf_current_func = funcName
      endif
      return
    endif
    if filereadable(confFile)
      " Magically wrap continuation lines
      let filecontents = split(
            \   substitute(
            \     join(readfile(confFile), "\n"),
            \   '\n\s*\\', ' ', 'g'),
            \ '\n')
      let fileFunction =   [ 'fun! g:dirconf_sourced.' . funcName .
                         \   '(dir, name, file)' ] +
                         \ [ 'let _DC_CpoSave = &cpo', 'set cpo&vim' ] +
                         \ [ 'let b:did_ftplugin = 1' ] +
                         \ [ 'let reload_eagerly = 0' ] +
                         \   filecontents +
                         \ [ 'let &cpo = _DC_CpoSave' ] +
                         \ [ 'return reload_eagerly' ] +
                         \ [ 'endfun' ]
      " create function for this dir
      call s:Echo(join(fileFunction, '\n'))
      call execute(fileFunction)
      let g:dirconf_eager[funcName] =
            \ g:dirconf_sourced[funcName](dir, pathName, confFile)
      if g:dirconf_verbose
        call s:Echo('dirconf.vim: created ' .
              \ string(g:dirconf_sourced[funcName]))
      endif
    else
      if g:dirconf_verbose
        call s:Echo('dirconf.vim: not sourcing file ' . confFile)
      endif
    endif
  endif
endfun

augroup DirConf
  autocmd!
  " TODO shoul we use BufReadPre instead?
  autocmd BufNewFile,BufRead * call <SID>Check()
augroup END

fun! s:EditDirConf(...)
  let editFiletype = 'vim'
  if a:0
    let editFiletype = a:000[0]
  endif
  let dir = s:FindParentDirContainingOneOf(g:dirconf_parent_files)
  if !empty(dir)
    let funcName = s:FuncName(dir)
    let dir = s:ShortDirName(dir)
    let dir .= '.' . editFiletype
    if editFiletype ==# 'vim' && has_key(g:dirconf_sourced, funcName)
      " Remove function so it will be sourced again
      call remove(g:dirconf_sourced, funcName)
    endif
    exe ':vsplit ' . escape(dir, '-#%' . g:dirconf_join)
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

command! -nargs=? DirConf call <SID>EditDirConf(<f-args>)

let &cpo= s:keepcpo
unlet s:keepcpo
