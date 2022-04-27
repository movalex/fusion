# Replace shot number in all savers based on comp name
# Comp name in episode_shot_author_version.comp format is required (106_0055_zf_v01.comp).
# Copyright 2022 Alexey Bogomolov (mail@abogomolov.com)
# License MIT
# v 1.1 13.04.2022

from pathlib import Path


def parse_comp_name(name=None):
    if not name:
        print("no name found")
        return
    try:
        name = Path(name).stem
        split_name = name.split("_")
        if len(split_name) < 4:
            print("Wrong name convention")
            return None

        return split_name

    except AttributeError:
        print("No comp name found")

def main():
    comp = fu.GetCurrentComp()
    savers = comp.GetToolList(False, "Saver").values()
    if not savers:
        print("Unable to parse the comp name")
        return
    comp_name = comp.GetAttrs()["COMPS_Name"]
    comp_parse = parse_comp_name(comp_name)

    if comp_parse:
        comp.StartUndo("Set Shot Nums")
        episode, shot, _, version = comp_parse
        for saver in savers:
            path = saver.Clip[1]
            parent = Path(path).parent
            ext = Path(path).suffix
            new_path = Path(rf"{parent}/{episode}_{shot}_{version}{ext}").resolve()
            print(f"new saver path: {new_path}")
            saver.Clip[1] = str(new_path)
        comp.EndUndo()



if __name__ == "__main__":
    main()
