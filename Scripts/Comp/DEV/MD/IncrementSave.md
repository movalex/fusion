# IncrementSave script

The script logic is based on [IncrementalSave tool](https://www.svenneve.com/?p=175) written by S.Neve / House of Secrets. The idea is to have granular incrementation of the Fusion compositions without cluttering current folder with version files. It is also a great companion to a VFX Connect workflow, because saving VFX Connect versions may be unwanted.

_Usage:_

* Run the script from `Scripts/Comp/IncrementSave` folder or use `Alt+S` shortcut
* The comp version will be saved to  `IncrementSave/<comp_name>` folder next to the current comp file. If this folder does not exists, it will be created.
* versions are saved with `0001` incrementing
* You can also set $INCREMENT_SAVE_PATH environment variable to have your increment saves in specific folder

_IMPORTANT NOTES:_ 

1. The package consists of two script, Python and Lua. Python script requires Python3. 
If by any chance you prefer to use Lua, feel free to use `hos_IncrementSave.lua` script, included to this this Reactor installation. This is original lua script written by @svenneve, fixed to support macos file paths. 
However Python3 version of the script has advantages: it works if the comp path has some non-ascii characters.
2. The increment save process is implemented in stages. That means, that the moment the script is run, current version of the comp will be immediately _copied_ to the increment folder _without saving_. And then the current comp is saved in it's current location. This is done on purpose, so you could have two copies of your work simultaneously: backed up comp before saving and a current state of the comp.

_Automatic saves:_

You can toggle this script based on Cron jobs or MS Scheduler. NB: Fusion Studio is required for external scripting.
Use this snippet as a staring point for your Increment save automation:

```python
    import BlackmagicFusion as bmd
    fusion = bmd.scriptapp('Fusion', 'localhost')
    comp = fusion.GetCurrentComp()
    comp.RunScript("Scripts:Comp/IncrementSave.py")
```
_Copyright:_ Alexey Bogomolov (mail@abogomolov.com), 2020

_License:_ [MIT](https://mit-license.org/)

_Version:_ v.1.0 - 2020/06/26



_Requirements:_ Python 3.6+