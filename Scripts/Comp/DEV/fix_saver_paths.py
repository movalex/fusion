# Replace shot number in all savers based on comp name
# Shot number in s### format must present in a comp name
# Copyright 2021 Alexey Bogomolov (mail@abogomolov.com)
# License MIT
# v 1.0 10.12.2021

import re


def get_shot_num(name=None):
    if not name:
        print("no name found")
        return
    try:
        shot_name = re.search("[._]([sS]\d+)[._]", name).group(1)
        return shot_name
    except AttributeError:
        print("No shot number found in the comp name")


if __name__ == "__main__":
    comp = fu.GetCurrentComp()
    savers = comp.GetToolList(False, "Saver").values()
    comp_name = comp.GetAttrs()["COMPS_Name"]
    shot_name = get_shot_num(comp_name)

    if shot_name and len(savers) > 0:
        comp.StartUndo("Set Shot Nums")
        for saver in savers:
            path = saver.Clip[1]
            new_path = re.sub("([sS]\d{2,})", shot_name, path)
            print(f"new saver path: {new_path}")
            saver.Clip[1] = new_path
        comp.EndUndo()
