"""
  Increment Save script
  by Alex Bogomolov
  
    The script logic is based on IncrementalSave script written by S.Neve / House of Secrets
    NOTE: The script requires Python3. If you are still using Python2,
    feel free to use IncrementSave.lua from this Reactor installation
    However Python version of IncrementSave has some advantages over the Lua one:
        - it will work correctly if the comp path has some non-ascii characters
        - increment save folder will look the same on Mac and PC - without the '.comp' part 
        - it is easier to read and maintain
    USAGE:
        - Run the script from Scripts/Comp/IncrementSave folder or use Alt+S shortcut
        - The folder IncrementSave will be created, if it does not exists, in comp folder
        - Inside IncrementSave folder there will be created a folder with a comp name, which contains the comp with
          incremented version number in ...0001.comp format
        - Set $INCREMENT_SAVE_PATH environment variable to have your increment saves in specific folder
    MIT License: https://mit-license.org/
    Copyright 2020 Alex Bogomolov
    v.1.0 - 2020/06/26:
        * initial release
    email: mail@abogomolov.com
    donations: https://paypal.me/aabogomolov/10usd
"""

import os
import re
import sys
from pathlib import Path

comp = fu.GetCurrentComp()
PATH_ENV = comp.MapPath(os.getenv("INCREMENT_SAVE_PATH"))
comp_attrs = comp.GetAttrs()


def get_save_path(path_env=None):
    if path_env:
        path_env = Path(path_env)
        comp_path = Path(comp_attrs["COMPS_FileName"])
        print(f"environment path found: {path_env}")
        if not path_env.exists():
            path_env.mkdir(parents=True, exist_ok=True)
        return path_env / comp_path.stem
    root_save_folder = "IncrementSave"
    comp_path = Path(comp.MapPath(comp_attrs["COMPS_FileName"]))
    return comp_path.parent / root_save_folder / comp_path.stem


def get_increment_number(path):
    comps = []
    increment_number = 0
    for file in path.iterdir():
        if file.suffix == ".comp":
            comps.append(file)
    if len(comps) > 0:
        for file in comps:
            num = re.findall(r"(\d{4}).comp$", str(file))[0]
            if int(num) > increment_number:
                increment_number = int(num)
    return increment_number


def increment_comp():
    if not (sys.version_info.major == 3 and sys.version_info.minor >= 6):
        print("this script requires Python version >= 3.6")
        return
    source_file = Path(comp_attrs["COMPS_FileName"])
    comp_name = Path(comp_attrs["COMPS_Name"])
    save_path = get_save_path(PATH_ENV)
    if not save_path.exists():
        save_path.mkdir(parents=True)
    number = get_increment_number(save_path)
    number += 1
    destination_file = save_path / comp_name.with_suffix(f".{number:04}.comp")
    print(f"saved comp version: {destination_file.name}")
    try:
        source_file.rename(str(destination_file))
    except OSError:
        print("source file name is empty")
    comp.Save(source_file)


if __name__ == "__main__":
    if comp_attrs["COMPS_FileName"] == "":
        comp.Save()
    else:
        increment_comp()
