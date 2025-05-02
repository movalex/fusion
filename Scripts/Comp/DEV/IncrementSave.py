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
    v.1.1 - 2022/12/20
    email: mail@abogomolov.com
"""

import os
import re
import sys
import shutil
from pathlib import Path
from log_utils import set_logging
from fusion_comp_utils import CompUtils

utils = CompUtils(comp)

comp = fu.GetCurrentComp()
PATH_ENV = comp.MapPath(os.getenv("INCREMENT_SAVE_PATH"))
ROOT_SAVE_FOLDER = "IncrementSave"
comp_attrs = comp.GetAttrs()


log = set_logging(script_name="Increment Save")


def get_increment_path(path_env=None):
    if path_env:
        log.info(f"Environment path found: {path_env}")
        path_env = Path(path_env)
        comp_path = Path(comp_attrs["COMPS_FileName"])
        return path_env / comp_path.stem
    comp_path = Path(comp.MapPath(comp_attrs["COMPS_FileName"]))
    return comp_path.parent / ROOT_SAVE_FOLDER / comp_path.stem


def get_increment_number(path):
    comps = []
    for file in path.iterdir():
        if file.suffix == ".comp" and re.search(r"\.\d{4}\.comp$", file.name):
            comps.append(file)
    number = len(comps) + 1
    return number


def increment_comp():
    if not (sys.version_info.major == 3 and sys.version_info.minor >= 6):
        log.error("This script requires Python version >= 3.6")
        return
    comp_path = utils.get_comp_name()
    if not comp_path:
        log.warning("Comp Name could not found. Save the comp!")
        comp.SaveAs()
    comp.Save(comp_path)
    comp_name = comp_path.stem
    increment_save_path = get_increment_path(PATH_ENV)
    if not increment_save_path.exists():
        try:
            increment_save_path.mkdir(parents=True)
        except Exception as e:
            log.error(f"Error Creating Inc: {e}")
            return
    number = get_increment_number(increment_save_path)
    if not number:
        log.error(
            "Existing incrementSave folder found. \nHowever the script could not get the latest increment number"
            "\nPlease check if all incrementSave files for the current comp are named correctly, and there's no cloud sync renaming issues"
        )
        return
    destination_file = increment_save_path / f"{comp_name}.{number:04}.comp"
    try:
        shutil.copy(comp_path, destination_file)
        # comp_path.rename(str(destination_file))
        log.info(f"Saved comp version: {destination_file.name}")
    except OSError as e:
        log.error(f"OSError raised:\n{e}")


if __name__ == "__main__":
    if comp_attrs["COMPS_FileName"] == "":
        comp.Save()
    else:
        increment_comp()
