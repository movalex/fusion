"""
  Increment Save script
  by Alexey Bogomolov
  
    Ths script is based on IncrementalSave.lua script written by S.Neve / House of Secrets
    Python2 and 3 are supported, but usage of Python3 is encouraged
    This version has some advantages over the Lua one:
        - it will work if the comp path has some non-ascii characters
        - save folder will look the same on Mac and PC - without '.comp' part 
              (Sic: comp.GetAtttr()["COMPS_Filename"] works differently on Windows and Mac!)
        - it is  easier to read and maintain
    MIT License:  https://mit-license.org/
    Copyright 2020 Alexey Bogomolov
    v.1.0 - 2020/06/26:
        * initial release
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
        print("environment path found: {}".format(path_env))
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
    source_file = Path(comp_attrs["COMPS_FileName"])
    comp_name = Path(comp_attrs["COMPS_Name"])
    save_path = get_save_path(PATHENV)
    if not save_path.exists():
        save_path.mkdir(parents=True)
    number = get_increment_number(save_path)
    number += 1
    dest_file = save_path / comp_name.with_suffix(".{:04}.comp".format(number))
    print("save destination: {}".format(dest_file))
    try:
        source_file.rename(str(dest_file))
    except OSError:
        print("source file name is empty")
    comp.Save(source_file)


if __name__ == "__main__":
    if comp_attrs["COMPS_FileName"] == "":
        comp.Save()
    else:
        increment_comp()
