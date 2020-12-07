# md2Reactor script

This is a script for converting `Markdown` formatted file to `BBcode` and `HTML` syntax.
Now you can use single `.md` file to create a neatly formatted description of Reactor tool for the [Reactor Submission page](https://www.steakunderwater.com/wesuckless/viewforum.php?f=33) and also make description for the [Atom file](https://www.steakunderwater.com/wesuckless/viewtopic.php?f=33&t=1799). All my recent submissions are prepared using this script. 

_Requirements:_

* Python 3.6+
* Markdown package to create Atom html file. This package is installed with `python3 -m pip install markdown` command 

_Description:_

Create a neatly formatted tool description os any other forum submission, then run the sciprt, and it will produce two files at the same location:
 
1. `filename_bbcode.txt` file for the STU forum submission
2. `filename_atom.html` file for Atom description.

The Md2Reactor script is installed in Scripts:Utility folder. You can launch it either as a standalone app, or via Fusion folder from `File --> Scripts --> md2Reactor`. It will open a filedialog window with a filter for `.md` files. Default location for the file search is `~/Desktop`, but the script will save last used folder path as fusion data and next time it is launched, it will open file dialog at the saved place.

You can also use this script as a commandline tool. It accepts multiple .md file as an argument. So you can easily convert multiple `.md` files with a wildcarded command:

* for MacOS or linux use this command for current folder: `python3 <path-to>/md2Reactor.py ./*.md`
* for Windows with Powershell: `py <path-to>\md2Reactor.py (Get-Item .\*.md).FullName`. Or create a `.bat` file:

    

, put it to a $Path environment and lanch

Here's a [cheat sheet](https://www.markdownguide.org/cheat-sheet/) for markdown syntax. Only basic markdown syntax is converted to BBCode.

_Copyright:_ Alexey Bogomolov (mail@abogomolov.com)

_License:_ [MIT](https://mit-license.org/)

_Version:_ 1.2 - [2020.11.24] 

_Donations:_ [PayPal.me](https://paypal.me/aabogomolov/5usd)