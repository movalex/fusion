# Attribute Spreadsheet

I'm a big fan of @svenneve's scripts. They are so cleverly written and I use them in every project, especially [DuplicateTool](https://www.svenneve.com/?p=922), [IncrementalSave](https://www.svenneve.com/?p=175), and now - [Attribute Spreadsheet](https://www.svenneve.com/?p=792).

Attribute Spreadsheet is a spreadsheet script to edit the input parameters of multiple Fusion tools at once.  It is extremely useful for batch tool changes, and a great help for any motion graphics tasks. The most amazing part that it works with any native or third party Fusion tool, such as OFX plugins, macros, Krokodove tools and so on. Any available input is accessible from a very convenient table view. You can link any input to another withexpression by a middle mouse drag. Besides some inputs, such at Text+ Font or Style, does not even allow to set expression manually. With Attribute spreadsheet you can do that easily too. As far as I know, this script is the fastest and the most reliable tool for batch changing parameters, and it should definitely be in Reactor.

*Usage:*

* Select one or more tools in Fusion flow and start the script or press "Refresh" button.
* Select multiple values in a single column, say, "Blend".
* Start typing new numeric value and hit Enter. All Blend values for selected tools will be changed accordingly
* Connect any number of the inputs to a single tool attribute by middle-click and drag toward the cell you are linking to.
* Enter `-x` to discard the expression. Once the expression is set, you cannot change the values in the table unless the expression is cleared.
* Use `+=`, `-=`, `*=`, `/=` and `%=` to do mathematical expressions with current numerical values. for example: enter `+=0.2123` to Transform's Size value, and it will become `1.2123`
* Use search bar to find inputs you like. You can search for multiple inputs, separated by spaces, like `size angle` to search both Size and Angle inputs in selected Transform tools.
* Enter expression to any number of point values. For instance, entering `=time` in the angle value will create `=time` expression, adding `=time` and `0.5` in Center values will create `Point(time, 0.5)` expression
* Enter `p` in any table cell and all corresponding input attributes will be listed in Console.
* Click on the row header to activate the tool
* Click on column header to sort inputs

Current version (0.2.3) has quite large changelog in comparison to the last known version of `hos_AttributeSpreadsheet`. You can find full list of new features and fixes inside a script file. 

_The most significant improvements:_
    
* Point data with X and Y elements are both adjustable and now work with mathematical modifiers
* Corner button will reset sorting to default state
* Tool name and ID is added to a table to improve sorting abilities
* You can add expressions to Point data values, such as Center.X, Center.Y
* Added logging, most errors are caught with Console feedback
* Set active tool by clicking on row header
* Use this script as a standalone tool (Fusion Studio feature). Provide a remote machine IP as an argument to a script to do remote management

*Requirements:*

* Python 3.6
* Fusion Standalone v.9 and v.16+, Davinci Resolve v.16+
* PySide2 (can be installed automatically)

*Automatic PySide2 installation*

My intention was to make this script as straightforward and easy to use as possible. Usually installing third party package to Python is pretty painless. But it would be much cooler to strip this step and offer automatic installation on a first launch. 

If there's no Pyside2 installation on the computer, the script will show a dialogue, whether you want to install the script automatically. If clicked `Ok`, it attempts to install Pyside2 using standard pip tools. Otherwise the command for manual installation will be shown in Console. Python modules manager `pip` should be already installed on the computer. It is a part of standard Python3 installation, thus the reason the script will require Python3 (also for maintenance and ideological purposes).

Automatic PySide2 installation process will be visible in Fusion console. In case installation fails, please report the bug here. Once Pyside2 is installed, launch the script again and standard UI will be shown:

*Known issues:*

* All fields except numerical or point data inputs are treated as text values. This prevents unexpected behavior when changing cells values. 
* Although script works perfectly both in Resolve and Fusion Standalone separately, sometimes, when both of this apps are loaded at the same time, the script cannot read the comp data properly. In this case you'll see `No comp data found. Probably both Resolve and Fusion are loaded?` error message. I'm looking forward to handle this issue as soon I understand why it is happening.
* You should avoid linking inputs to each other. This is a known bug: if you link `Transform1.Size` to `Transform2.Size` and then try to link expression from `Transform2.Size` back to `Transform1.Size`, Fusion will crash immediately. The same will happen if you try to do that with a script. Just don't.

*TODO:*

* Add combobox to inputs with list data, such as `INPIDT_ComboControl_ID` or `INPIDT_MultiButtonControl_ID`, so you could choose the appropriate values from dropdown instead of typing values manually. This can be tricky, because some Fusion inputs addressed by key ('1.0', '2.0') and some - by value ('Red', 'XYZ' etc). 
* Add a completer with the most commonly used search commands. For instance, if you've already been searching `red green blue`, this query will be suggested once you type `r` in search area.
* Add an option for partial middle-drag/linking Point data, such as link only X values, so the expression would be like `Point(Transform1.Center.X, 0.5)`. Currently it is possible by manually adding expression text to a Point data, so probably not necessary at all.
* Add `Select by ID` button to quickly select and load to the table all tools with the same ID as the active tool. However this can be done with ToolManager script, so again questionable.
* Please suggest any other improvements.
  
*Version:* 0.2.3 - 2020/12/04

*Copyright:* 2011-2013, Sven Neve, 2019-2020 additions by Alexey Bogomolov [mail@abogomolov.com](mail@abogomolov.com)

*License:* [MIT](https://mit-license.org/)

*Donations:* [PayPal.Me](https://paypal.me/aabogomolov/10usd)