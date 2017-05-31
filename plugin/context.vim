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
" TODO: iterate looking for /.git or /package.json to find project root
" TODO: Make variables available to the sorced file like s:path, etc.
" TODO: Rename to Cv, shortcuts CV, CD, vim, doc
"
"if &cp || exists("g:loaded_dirconf")
"  finish
"endif
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
  let g:dirconf_join = '%'
endif

if !exists('g:dirconf_parent_files')
  let g:dirconf_parent_files = ['.git/config',
                              \ 'Cargo.toml', 'configure']
endif

if !isdirectory(g:dirconf_dir) && exists('*mkdir')
  call mkdir(g:dirconf_dir, 'p', 0700)
  echomsg 'created ' . g:dirconf_dir
endif

fun! FindParentDirContainingOneOf(paths)
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

fun! ShortDirName(dir)
  return g:dirconf_dir . '/' . substitute(substitute(
        \ a:dir, '^' . $HOME, 'HOME', ''), '/', g:dirconf_join, 'g') 
endfun

let s:sourced = {}

fun! s:Check()
  " TODO This could be sped up
  let dir = FindParentDirContainingOneOf(g:dirconf_parent_files)
  if !empty(dir)
    let vimFile = ShortDirName(dir) . '.vim'
    if !has_key(s:sourced, vimFile) && filereadable(vimFile)
      exe 'source ' . escape(vimFile, '%#')
      " TODO Place the contents into a variable to be reevaluated for each buffer
      " TODO join(readfile($HOME . '/.vim/dirconf/HOME%yow%debugger.html/conf.vim'), '\n')
      let s:sourced[vimFile] = 1
      if g:dirconf_verbose
        echomsg 'sourced ' . vimFile
      endif
    elseif g:dirconf_verbose
      echomsg 'not sourcing file ' . vimFile
    endif
  endif
endfun

augroup DirConf
  autocmd!
  autocmd BufNewFile,BufReadPre * call <SID>Check()
augroup END

fun! s:EditDirConf(...)
  if !empty(a:000)
    let filename = a:000[0]
  else
    let filename = 'conf.vim'
  endif
  let dir = FindParentDirContainingOneOf(g:dirconf_parent_files)
  if !empty(dir)
    let dir = ShortDirName(dir)
    if !isdirectory(dir)
      call mkdir(dir, 'p', 0700)
    endif
    let dir .= '/' . filename
    echomsg 'open ' . dir
    exe ':vsplit ' . escape(dir, '%#')
  endif
endfun

command! -nargs=* DirConf call <SID>EditDirConf(<f-args>)

let &cpo= s:keepcpo
unlet s:keepcpo
