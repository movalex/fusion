# Replace shot number in all savers based on comp name
# Comp name should look like this: <episode number>###_<shot number>####_<author>_<version>.comp
# Copyright 2021 Alexey Bogomolov (mail@abogomolov.com)
# License MIT
# v 1.1 10.12.2021

import re
from pathlib import Path


def get_shot_num(name=None):
    """get shot number from comp name using pattern:
    <episode number>_<shot number>_
    """

    if not name:
        print("no comp name found")
        return
    try:
        episode_num, shot_num = re.findall("(\d{3})[._](\d{4,})[._]", name)[0]
        return episode_num, shot_num
    except AttributeError:
        print("No shot number found in the comp name")


if __name__ == "__main__":
    comp = fu.GetCurrentComp()
    savers = comp.GetToolList(False, "Saver").values()
    comp_name = comp.GetAttrs()["COMPS_Name"]
    ep, shot = get_shot_num(comp_name)
    print(f"found episode: {ep}, shot number: {shot}")

    if shot and len(savers) > 0:
        comp.StartUndo("Set Shot Nums")
        for saver in savers:
            path = saver.Clip[1]
            file_path = Path(saver.Clip[1])
            new_version = re.sub("(\d{4,})", shot, file_path.name)
            new_version = re.sub("^(\d{3})", ep, new_version)
            new_path = file_path.parent / new_version
            print(f"new saver path: {new_path}")
            saver.Clip[1] = str(new_path)
        comp.EndUndo()
