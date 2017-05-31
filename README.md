# Context.vim - Access out of repo files

Vim config and files maintained out of repo

## Purpose of tagdir

* **DONE** Upon LID or tag lookup set `&tags` and `g:LID_File` of the current buffer.
  The paths in these variables should point to one or more comma separated
  directories in `~/.cache/tagdir/#some#path/...`.  If the beginning of 
  `#some#path` equals `${HOME}` it is replaced with `HOME`.

* The `tagdir` script configuration is stored in 
  `~/.config/tagdir/#some#file.ignore`.  The start of the file name may be
  replaced with `HOME`.

  TODO: Tagdir config should be way more elegant.
  TODO: The vim script should be able to edit tagdir.ignore files too.

* Later: Optionally run the tagdir script with the source and destination dirs
  as arguments so the ID and tags files can be written to any dir.

## The context (dirconf) plugin

* Configure global vim settings when opening a file and every time a new file
  or buffer is opened for editing.

  The file should be named `HOME#dir.vim` and should be made into a function
  so it can be executed with an autocmd every time the buffer is entered for
  editing.

## Other

* notinrepo.vim

* Assoc? bad
