" 
" Call 
"
"     :DirConf
" 
" to edit the file with options for this specific dir.
"
" * Keep config outside of repos
"
" Config:
"
"     let g:dirconf_dir = '/path/to/store/configurations'
"     let g:dirconf_verbose = 0
"     
" TODO: Make variables available to the sorced file like s:path, etc.
" TODO: Handle continuation lines in scripts ie /\n\s*\\/

if &cp || exists("g:loaded_dirconf")
  finish
endif
let g:loaded_dirconf = "v0.0.1"
let s:keepcpo = &cpo
set cpo&vim

if !exists('g:dirconf_dir')
  let g:dirconf_dir = $HOME . '/.vim/dirconf'
endif

if !exists('g:dirconf_verbose')
  let g:dirconf_verbose = 1
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
let g:dirconf_current_func = ''

fun! s:Check()
  call s:Echo("dirconf.vim: Check")
  let dir = s:FindParentDirContainingOneOf(g:dirconf_parent_files)
  if !empty(dir)
    let confFile = s:ShortDirName(dir) . '.vim'
    let funcName = s:FuncName(dir) 
    if has_key(g:dirconf_sourced, funcName)
      if g:dirconf_current_func != funcName
        call g:dirconf_sourced[funcName]()
        let g:dirconf_current_func = funcName
      endif
      return
    endif
    " !has_key(g:dirconf_sourced, funcName)
    if filereadable(confFile)
      let filecontents = readfile(confFile)
      let fileFunction = [   'fun! g:dirconf_sourced.' . funcName . '()' ] +
                         \   filter(filecontents, "v:val !~ '^\s*\"'") +
                         \ [ 'endfun' ]
      " create function for this dir
      call s:Echo(join(fileFunction, '\n'))
      call execute(fileFunction)
      call g:dirconf_sourced[funcName]()
      if g:dirconf_verbose
        call s:Echo('dirconf.vim: created ' . string(g:dirconf_sourced[funcName]))
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
  autocmd BufNewFile,BufReadPre * call <SID>Check()
augroup END

fun! s:EditDirConf()
  let dir = s:FindParentDirContainingOneOf(g:dirconf_parent_files)
  if !empty(dir)
    let dir = s:ShortDirName(dir)
    let dir .= '.vim'
    let funcName = s:FuncName(dir)
    " Remove function so it will be sourced again
    call remove(g:dirconf_sourced, funcName)
    exe ':vsplit ' . escape(dir, '-#%' . g:dirconf_join)
  endif
endfun

command! -nargs=0 DirConf call <SID>EditDirConf()

let &cpo= s:keepcpo
unlet s:keepcpo
