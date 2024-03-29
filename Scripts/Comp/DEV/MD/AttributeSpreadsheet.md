# Attribute Spreadsheet

One of my favorite tools - [Attribute Spreadsheet](https://www.svenneve.com/?p=792), was written by Sven Neve in 2013. I did not find any traces of it to be updated to support the latest Fusion and Resolve versions, and it looks like to be abandoned for 7 years now. This is my attempt of reviving this tool while adding new features to it.

_AttributeSpreadsheet_ is a spreadsheet script to edit the input parameters of multiple Fusion tools at once. It is extremely useful for batch tool changes, and a great help for any motion graphics tasks. The most amazing part that it works with any native or third party Fusion tool, such as OFX plugins, macros, Krokodove tools and so on. Any available input is accessible from a very convenient table view. You can also  link any input to another with expression by a middle mouse drag. Some tools, such at Text+ `Font` or `Style`, does not even allow setting expression manually. With _AttributeSpreadsheet_ you can do that easily too. As far as I know, this is the fastest, and the most reliable tool for a batch changing parameters or linking multiple Fusion inputs. It should definitely be in Reactor.

*Requirements:*

* Python 3.6
* Fusion Standalone v.9 and v.16+, Davinci Resolve v.16+
* PySide2 (can be installed automatically)

*Usage:*

* Select one or more tools in Fusion flow and start the script or press "Refresh" button.
* Select multiple values in a single column, say, "Blend".
* Start typing new numeric value and hit Enter. All Blend values for selected tools will be changed accordingly. That's the basic functionality.
* To link multiple tool's inputs to another tool with expression, select the column and drag with middle-click towards the cell you are linking to. 
* Enter `-x` to discard the expression on single or multiple inputs. Once the expression is set, you cannot change the values in the table unless the expression is cleared.
* Use `+=`, `-=`, `*=`, `/=` and `%=` to do mathematical expressions with current numerical values. for example: enter `+=0.2123` to default Transform Size value, and it will become `1.2123`
* Use search bar to find inputs. You can search for multiple inputs, separated by spaces, like `size angle` to search both Size and Angle inputs.
* Enter numerical values or expression to point values, such as `Pivot` or `Center`. For instance, enter `=time` in the Transform Angle cell will create `=time` expression, adding `=time` and `0.35` in Center `X` and `Y` values will create `Point(time, 0.35)` expression.
* Enter `p` in any table cell and all corresponding input attributes will be listed in Console.
* Click on the row header (tool name) to activate the tool.
* Click on column header to sort inputs alphabetically. Click on the corner button to reset sorting to default state.

The current version (0.2.3) has quite large changelog in comparison to the last known version of `hos_AttributeSpreadsheet`. You can find full list of new features and fixes inside a script file. The most significant improvements:
    
* Point data with X and Y elements are both adjustable and now work with mathematical modifiers.
* You can add expressions to Point data values, such as `Point(Pivot.X, 0.5)`
* Corner button will reset sorting to default state
* Tool name and ID is added to a table to improve sorting abilities
* Added logging, most errors are caught with Console feedback
* Set active tool by clicking on row header
* Use this script as a standalone tool (Fusion Studio feature). Provide a remote machine IP as an argument to a script to do remote management

*Automatic PySide2 installation*

My intention was to make this script as straightforward and easy to use as possible. Usually installing third party package to Python is a painless task. So we go further and strip this step, offering automatic PySide2 installation on a first launch. 

If there's no Pyside2 installation found on the computer, the script will show a dialogue, whether you want to install the package automatically. If clicked `Ok`, it attempts to install Pyside2 using standard pip tools. Otherwise, the command for manual installation will be shown in Console. Python modules manager `pip` should be already installed on the computer. It is a part of standard Python3 installation, thus the reason the script will require Python3 (also for maintenance purposes). Automatic PySide2 installation process will be visible in Fusion console. In case installation fails, please report the bug here. Once Pyside2 is installed, launch the script again and UI will appear.

*Known issues:*

* All fields except numerical or point data inputs are treated as text values. This prevents unexpected behavior when changing cells values. 
* Although script works both in Davinci Resolve and Fusion Standalone, sometimes, when both of these apps are loaded, the script cannot read the comp data properly. In this case you'll see `No comp data found. Probably both Resolve and Fusion are loaded?` error message. I'm looking forward to handling this issue as soon I understand why this is happening.
* You should avoid linking inputs to each other. This is a known bug: if you link `Transform1.Size` to `Transform2.Size` and then try to link expression from `Transform2.Size` back to `Transform1.Size`, Fusion will crash immediately. The same will happen if you try to do that with a script. Just don't.

*TODO:*

* Add combobox to inputs with list data, such as `INPIDT_ComboControl_ID` or `INPIDT_MultiButtonControl_ID`, so you could choose the appropriate values from a dropdown instead of typing values manually. This can be tricky, because some Fusion inputs addressed by key ('1.0', '2.0') and some - by value ('Red', 'XYZ' etc). Also, this should probably exclude Fonts.
* Add a completer with the most commonly used search commands. For instance, if you've already been searching `red green blue`, this query will be suggested once you type `r` in search area.
* Add an option for partial middle-drag/linking Point data, such as link only `X` values, or only `Y`, so the expression would be like `Point(Transform1.Center.X, 0.5)`. Currently, it is possible by typing expression text to a Point X cell.
* Add `Select by ID` button to quickly select and load to the table all tools with the same ID as the active tool. However, this can be done with ToolManager script, so questionable.
* Please suggest any other improvements.

Take a look at this feature review made by the author of the original script. Please note that some of mentioned bugs and/or features are fixed/implemented in this release. And yes, this last sentence implies that new bugs could have been implemented as well, although I did my best to avoid them. Please report any issues here.

https://www.youtube.com/watch?v=b97Q3mj3an0

https://www.youtube.com/watch?v=uarUXcZpp8Q
  
*Version:* 0.2.3 - [2020/12/07]

*Copyright:* 2011-2013, Sven Neve (House of Secrets); 2019-2020 additions by Alexey Bogomolov [mail@abogomolov.com](mail@abogomolov.com)

*License:* [MIT](https://mit-license.org/)
