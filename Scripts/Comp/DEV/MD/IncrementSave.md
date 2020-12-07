# IncrementSave   script


The script logic is based on [IncrementalSave tool](https://www.svenneve.com/?p=175) written by S.Neve / House of Secrets. The idea is to have granular incrementation of the Fusion compositions without cluttering current folder with version files. It is also a great companion to a VFX Connect workflow, because saving VFX Connect versions may be unwanted.

_Usage:_
* Run the script from `Scripts/Comp/IncrementSave` folder or use `Alt+S` shortcut
* The comp version will be saved to  `IncrementSave/<comp_name>` folder next to the current comp file. If this folder does not exists, it will be created.
* versions are saved with `0001` incrementing
* You can also set $INCREMENT_SAVE_PATH environment variable to have your increment saves in specific folder

_NOTE:_ The script requires Python3. If by any chance you prefer to use Lua, feel free to use `hos_IncrementSave.lua` script, included to this this Reactor installation. This is original lua script written by @svenneve, fixed to support macos file paths. 

However Python3 version of the script has some advantages: 

* it works if the comp path has some non-ascii characters.
* increment save folder will look the same on Mac and PC - without the '.comp' part

_Copyright:_ Alexey Bogomolov (mail@abogomolov.com), 2020

_License:_ [MIT](https://mit-license.org/)

_Version:_ v.1.0 - 2020/06/26

_Donations:_ [PayPal.me](https://paypal.me/aabogomolov/10usd)

_Requirements:_ Python 3.6+