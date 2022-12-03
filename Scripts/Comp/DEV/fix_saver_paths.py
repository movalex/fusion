# Replace shot number in all savers based on comp name
# Comp name in episode_shot_author_version.comp format is required (106_0055_zf_v01.comp).
# Copyright 2022 Alexey Bogomolov (mail@abogomolov.com)
# License MIT
# v 1.1 13.04.2022

from pathlib import Path

comp = fu.GetCurrentComp()
COMP_FOLDER = "FUSION"
AUTHOR = "ab"
VERSION = "v01"


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


def save_comp():
    try:
        loader = comp.GetToolList(True, "Loader")[1]
    except KeyError:
        print("no Loader selected")
        return
    loader_path = Path(comp.MapPath(loader.Clip[1]))
    parse_name = loader_path.parts[-2]
    show, episode, shot = parse_name.split("_")
    folder = loader_path.parents[3]
    print(f"parent folder: {folder}\nepisode: {episode}\nshot: {shot}\n")
    new_folder = Path(folder) / COMP_FOLDER / f"{episode}-{shot}"
    Path.mkdir(new_folder, parents=True, exist_ok=True)
    print(f"folder {new_folder} is created!")
    comp.Save(str(new_folder / f"{episode}_{shot}_{AUTHOR}_{VERSION}"))


def main():
    comp = fu.GetCurrentComp()
    savers = comp.GetToolList(False, "Saver").values()
    if not savers:
        print("Unable to parse the comp name")
        return
    save_comp()
    comp_name = comp.GetAttrs()["COMPS_Name"]
    comp_parse = parse_comp_name(comp_name)

    if comp_parse:
        comp.StartUndo("Set Shot Nums")
        episode, shot, _, version = comp_parse
        for saver in savers:
            path = saver.Clip[1]
            parent = Path(path).parent
            ext = Path(path).suffix
            if ext in ['.exr', '.dpx']:
                ext = f".{ext}"
            new_path = Path(rf"{parent}/{episode}_{shot}_{version}{ext}")
            print(f"new saver path: {new_path}")
            saver.Clip[1] = str(new_path)
        comp.EndUndo()


if __name__ == "__main__":
    main()
