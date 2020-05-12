"""
  Increment Save script
  by Alexey Bogomolov
  
  Ths script is based on IncrementalSave.lua script written by S.Neve / House of Secrets
    NOTE: This version of the script works with Python3 only, since Python2 is deprecated
    If you are still using Python2 feel free to alter all f-strings to .format() or use IncrementSave.lua
    However, this version has some advantages over the Lua one:
        - it will work if the comp path has some non-ascii characters
        - save folder will look the same on Mac and PC - without '.comp' part 
              (comp.GetAtttr()["COMPS_Filename"] works differently on windows and mac)
        - In my opinion it is faster and easier to read and maintain
    MIT License:  https://mit-license.org/
    Copyright 2020 Alexey Bogomolov
    Version: 1.0
    email: mail@abogomolov.com
    donations: https://paypal.me/aabogomolov
"""
import os
import platform
import re
import sys
from pathlib import Path

comp = fu.GetCurrentComp()
PATHENV = comp.MapPath(os.getenv("INCREMENT_SAVE_PATH"))
comp_attrs = comp.GetAttrs()


def get_save_path(path_env=None):
    if path_env:
        path_env = Path(path_env)
        comp_path = Path(comp_attrs["COMPS_FileName"])
        print(f"environment path found: {path_env}")
        if not path_env.exists():
            # print("no save directory found, creating now")
            path_env.mkdir(parents=True, exist_ok=True)
        return path_env / comp_path.stem
    root_save_folder = "IncrementSave"
    comp_path = Path(comp.MapPath(comp.GetAttrs()["COMPS_FileName"]))
    return comp_path.parent / root_save_folder / comp_path.stem


def get_increment_number(path):
    comps = []
    increment_number = 0
    for file in path.iterdir():
        if file.suffix == ".comp":
            comps.append(file)
    if len(comps) > 0:
        for file in comps:
            num = re.findall("(\d{4}).comp$", str(file))[0]
            if int(num) > increment_number:
                increment_number = int(num)
    return increment_number


def increment_comp():
    if not (sys.version_info.major == 3 and sys.version_info.minor >= 6):
        print("this script requires Python version >= 3.6")
        return
    source_file = Path(comp_attrs["COMPS_FileName"])
    comp_name = Path(comp_attrs["COMPS_Name"])
    # print(f"source: {source_file}")
    save_path = get_save_path(PATHENV)
    if not save_path.exists():
        save_path.mkdir(parents=True)
    number = get_increment_number(save_path)
    number += 1
    dest_file = save_path / comp_name.with_suffix(f".{number:04}.comp")
    print(f"save destination: {dest_file}")
    source_file.rename(str(dest_file))
    comp.Save(source_file)


if __name__ == "__main__":
    if comp_attrs["COMPS_FileName"] == "":
        comp.Save()
    increment_comp()
