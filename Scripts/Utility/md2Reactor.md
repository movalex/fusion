# md2Reactor script

This is a script for converting `Markdown` formatted file to `BBcode` and `HTML` syntax.
Now you can use single .md file to create a neatly formatted description of Reactor tool for the [Reactor Submission page](https://www.steakunderwater.com/wesuckless/viewforum.php?f=33) and also make description for the [Atom file](https://www.steakunderwater.com/wesuckless/viewtopic.php?f=33&t=1799).

_Requirements:_

* Python3
* markdown package to create Atom html file. Markdown is installed with `python -m pip install markdown` command 

I'm a pretty lazy person and the fact I need to create three differently formatted files to add a single Reactor submission always cheered me down. Now you may just want to create a single .md file, and the script will produce two more files at the same location:
 
1. `filename_bbcode.txt` file for the STU forum submission
2. `filename_atom.html` file for Atom description.

The script is located in Scripts:Utility folder. You can launch it either as a standalone app, or via Fusion folder from `File --> Scripts --> md2Reactor`. It will open a filedialog window with a filter for `.md` files. Default location for the file search is `~/Desktop`, but the script will save last used folder path as fusion data and next time it is launched, it will open file dialog at the saved place.

You can also use this script as a commandline tool. It accepts .md file as an argument.