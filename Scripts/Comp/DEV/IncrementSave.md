# IncrementSave.py script

_Copyright:_ Alexey Bogomolov (mail@abogomolov.com)

_License:_ MIT License: https://mit-license.org/

_version:_ v.1.0 - 2020/06/26

_donations:_ [PaypalMe](https://paypal.me/aabogomolov)


The script logic is based on IncrementalSave tool written by S.Neve / House of Secrets. The idea is to have ganular incremention of the Fusion compositions without cluttering current folder with version files. It is also a great companion to a VFX Connect workflow, because sometimes saving VFX Connect version may become a tedious task.

_Usage:_

* Run the script from `Scripts/Comp/IncrementSave` folder or use `Alt+S` shortcut
* The comp version will be saved to  IncrementSave/comp_name folder next to the current comp file. If this folder does not exists, it will be created.
* versions are saved with `0001` incremention
* You can also set $INCREMENT_SAVE_PATH environment variable to have your increment saves in specific folder

_Key features:_

* new comp version will be saved next to the current comp in the `IncrementSave` folder with a subfolder named as the current comp name. 

* the script will work correctly if the comp path has non-ascii characters

* increment save folder will look the same on Mac and PC - without the '.comp' part


_NOTE:_

The script requires Python3. If you are still using Python2, feel free to use hos_IncrementSave.lua from this Reactor installation