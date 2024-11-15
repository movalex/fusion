#!/usr/bin/env python

"""
    Set new comp from template
    New comp will be created in COMP_FOLDER location,
    with episode_shot_author_version.comp format (106_0055_ab_v01.comp).
    
    License:
    Copyright © 2022 Alexey Bogomolov (mail@abogomolov.com)
    VESION: 1.3

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

import re
from pathlib import Path
from comp_utils import set_range, get_loader

comp = fu.GetCurrentComp()
COMP_FOLDER = "FUSION"
PROJECT = "VGM"
AUTHOR = "ab"


def get_loader():
    """get selected loader"""
    try:
        loader = comp.GetToolList(True, "Loader")[1]
        return loader
    except KeyError:
        print("no Loader selected")


def parse_loader_path(loader):
    loader_path = Path(comp.MapPath(loader.Clip[1]))
    parse_name = loader_path.parts[-2]
    try:
        episode, shot = re.search("(\d{3})?_(\d{4})", parse_name).groups()
        if not episode:
            episode = ""
    except AttributeError:
        return None
    project_folder = loader_path.parents[2]
    return project_folder, episode, shot


def create_comp_folder(folder, episode, shot):
    """build comp folder from the parsed loader data"""

    print(f"parent folder: {folder}\nepisode: {episode}\nshot: {shot}\n")

    fusion_folder = Path(folder) / COMP_FOLDER / f"{PROJECT}-{episode}-{shot}"
    if not episode:
        fusion_folder = Path(folder) / COMP_FOLDER / f"{PROJECT}-{shot}"
    try:
        Path.mkdir(fusion_folder, parents=True, exist_ok=False)
    except FileExistsError:
        print("comp folder already exists")
    else:
        print(f"folder {fusion_folder} is created!")
    return fusion_folder


def update_savers(version, episode, shot):
    """update saver paths with comp details and version"""

    savers = comp.GetToolList(False, "Saver").values()
    if not savers:
        print("No savers found in comp")
        return
    comp.StartUndo("Set Shot Nums")
    for saver in savers:
        path = saver.Clip[1]
        parent = Path(path).parent
        ext = Path(path).suffix
        if ext in [".exr", ".dpx"]:
            ext = f".{ext}"
        new_path = Path(rf"{parent}/{PROJECT}_{episode}_{shot}_v{version:02d}{ext}")
        if not episode:
            new_path = Path(rf"{parent}/{PROJECT}_{shot}_v{version:02d}{ext}")
        print(f"new saver path: {new_path}")
        saver.Clip[1] = str(new_path)
    comp.EndUndo()


def save_comp(folder, episode, shot) -> int:
    """build comp name and path and save the comp"""

    fusion_folder = create_comp_folder(folder, episode, shot)
    comp_version = 1

    new_comp = (
        fusion_folder / f"{PROJECT}_{episode}_{shot}_{AUTHOR}_v{comp_version:02d}.comp"
    )
    if not episode:
        new_comp = fusion_folder / f"{PROJECT}_{shot}_{AUTHOR}_v{comp_version:02d}.comp"
    while new_comp.exists():
        comp_version += 1
        new_comp = (
            fusion_folder
            / f"{PROJECT}_{episode}_{shot}_{AUTHOR}_v{comp_version:02d}.comp"
        )
        if not episode:
            new_comp = (
                fusion_folder / f"{PROJECT}_{shot}_{AUTHOR}_v{comp_version:02d}.comp"
            )
    comp.Save(str(new_comp))

    return comp_version


def main():
    loader = get_loader()
    if not loader:
        return
    set_range(loader)
    project_folder, episode, shot = parse_loader_path(loader)
    if not shot:
        print("shot number not parsed")
        return
    comp_version = save_comp(project_folder, episode, shot)
    update_savers(comp_version, episode, shot)


if __name__ == "__main__":
    main()
