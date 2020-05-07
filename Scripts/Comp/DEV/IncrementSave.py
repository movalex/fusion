"""
  Increment Save script
  by Alex Bogomolov
  
  Ths script is based on IncrementalSave.lua script written by S.Neve / House of Secrets

    NOTE: This version of thh script works with Python3 only
    However, it has some advantages over the lua one:
        - it will save version if the path has some non-ascii characters
        - save folder will look the same on Mac and PC - without '.comp' part 
          (comp.GetAtttr()["COMPS_Filename"] works differently on windows and mac)
        - possibly a bit cleaner to read and maintain

"""
import os
import platform
import re
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


def get_comp_files(path):
    comps = []
    for file in path.iterdir():
        if file.suffix == ".comp":
            comps.append(file)
    return comps


def increment_comp():
    number = 0
    source_file = Path(comp_attrs["COMPS_FileName"])
    comp_name = Path(comp_attrs["COMPS_Name"])
    # print(f"source: {source_file}")
    save_path = get_save_path(PATHENV)
    if not save_path.exists():
        save_path.mkdir(parents=True)
    comp_list = get_comp_files(save_path)
    if len(comp_list) > 0:
        for file in comp_list:
            num = re.findall("(\d{4}).comp$", str(file))[0]
            if int(num) > number:
                number = int(num)
    number += 1
    dest_file = save_path / comp_name.with_suffix(f".{number:04}.comp")
    # print(f"saving to destination: {dest_file}")
    source_file.rename(str(dest_file))
    comp.Save(source_file)


if __name__ == "__main__":
    if comp_attrs["COMPS_FileName"] == "":
        comp.Save()
    increment_comp()
