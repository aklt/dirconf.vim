# Context.vim - Access out of repo files

Vim config and files maintained out of repo

## Purpose of tagdir

The tagdir plugin should:

* Upon LID or tag lookup set a variable `b:...` on each buffer pointing to the
  dir where the ID and tags files live.  If the variable is already set
  `g:LID_File` and `&tags` should be set to this value so it matches the
  current file.

* Later: Optionally run the tagdir script with the source and destination dirs
  as arguments so the ID  and tags files can be written.

The dirconf plugin should:

* Configure global vim settings when opening a file and every time a new file
  or buffer is opened for editing.

  The file should be named `HOME%dir.vim` and should be made into a function
  so it can be executed with an autocmd every time the buffer is entered for
  editing.

## Name for this plugin

* Context is bad as it clashes with
    http://wiki.contextgarden.net/What_is_ConTeXt

* notinrepo.vim

* Assoc? bad
