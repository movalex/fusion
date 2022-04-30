#!/usr/bin/env python

"""
    Set new comp from template
    New comp will ve created in COMP_FOLDER location,
    with episode_shot_author_version.comp format (106_0055_zf_v01.comp).
    
    License:
    Copyright © 2022 Alexey Bogomolov (mail@abogomolov.com)
    VESION: 1.2

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
    OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

"""

from pathlib import Path

comp = fu.GetCurrentComp()
COMP_FOLDER = "FUSION"
AUTHOR = "ab"
COMP_VERSION = 1


def verify_comp_template(comp):
    if not comp.GetData("IS_TEMPLATE"):
        return False
    return True


def get_loader():
    try:
        loader = comp.GetToolList(True, "Loader")[1]
        return loader
    except KeyError:
        print("no Loader selected")


def parse_loader_path(loader):
    loader_path = Path(comp.MapPath(loader.Clip[1]))
    parse_name = loader_path.parts[-2]
    _, episode, shot = parse_name.split("_")
    folder = loader_path.parents[3]
    return folder, episode, shot


def create_comp_folder(folder, episode, shot):
    """create comp folder from currently selected loader"""

    print(f"parent folder: {folder}\nepisode: {episode}\nshot: {shot}\n")

    new_folder = Path(folder) / COMP_FOLDER / f"{episode}-{shot}"
    try:
        Path.mkdir(new_folder, parents=True, exist_ok=False)
    except FileExistsError:
        print("comp folder already exists")
    else:
        print(f"folder {new_folder} is created!")
    return new_folder


def save_comp(folder, episode, shot) -> int:
    """parse comp name from the current loader and save comp file to COMP_FOLDER"""

    new_folder = create_comp_folder(folder, episode, shot)

    version = COMP_VERSION
    new_comp = new_folder / f"{episode}_{shot}_{AUTHOR}_v{version:02d}.comp"
    while new_comp.exists():
        version += 1
        new_comp = new_folder / f"{episode}_{shot}_{AUTHOR}_v{version:02d}.comp"

    comp.Save(str(new_comp))
    comp.SetData("IS_TEMPLATE")

    return version


def main():
    if not verify_comp_template(comp):
        print(
            "current comp is not set as template\nnot processed further for safety"
            " reasons\nto set comp as  template, run `comp.SetData('IS_TEMPLATE',"
            " True)` in Fusion Py3 console"
        )
        return

    loader = get_loader()
    if not loader:
        return
    try:
        folder, episode, shot = parse_loader_path(loader)
        if not episode:
            print("comp not parsed")
            return
    except Exception as e:
        print(f"exception returned: {e}")
        return

    version = save_comp(folder, episode, shot)

    savers = comp.GetToolList(False, "Saver").values()
    if not savers:
        print("No savers found in comp")
        return
    comp_name = comp.GetAttrs()["COMPS_Name"]

    if comp_name:
        comp.StartUndo("Set Shot Nums")
        for saver in savers:
            path = saver.Clip[1]
            parent = Path(path).parent
            ext = Path(path).suffix
            new_path = Path(rf"{parent}/{episode}_{shot}_{version:02d}{ext}")
            print(f"new saver path: {new_path}")
            saver.Clip[1] = str(new_path)
        comp.EndUndo()


if __name__ == "__main__":
    main()
