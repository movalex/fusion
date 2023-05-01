#!/usr/bin/env python

"""
    Setup New Comp from Selected Loader

    The file convention for this project is:
    project_shot_author_version.comp
    i.e.: CON_0160_ab_v01.comp

    USAGE:
        1. open comp template in `2210_Consumed\PROJECTS\#Fusion Template` folder
        2. select the loader and choose the file you've been assigned to
        3. run the script. 

    What the script does:
    * create comp folder, if not exists
    * save comp file with correct name
    * update the savers paths according to new comp name
    * set render range based on the loader's length

    If the script is run multiple time, new comp version will be created.
    To set the comp author to your initials adjust the AUTHOR variable in the script source.

    VESION: 1.3

    License:
    Copyright © 2022 Alexey Bogomolov (mail@abogomolov.com)

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

comp = fu.GetCurrentComp()

PARSE_EPISODES = False
AUTHOR = "ab"
PROJECT_SHORT = "CON"
PROJECTS = Path(comp.MapPath(r"Z:\2210_Consumed\PROJECTS"))


def get_loader():
    """get selected loader"""
    try:
        loader = comp.GetToolList(True, "Loader")[1]
        return loader
    except KeyError:
        print("no Loader selected")


def parse_loader(loader):
    loader_path = Path(comp.MapPath(loader.Clip[1]))
    file_name = loader_path.name
    try:
        episode, shot = re.search("(\d{3})_(\d{4})", file_name).groups()
    except ValueError:
        return
    return episode, shot


def create_comp_folder(episode=None, shot=None):
    """build comp folder from the parsed loader data"""
    if PARSE_EPISODES:
        print(f"parent folder: {PROJECTS}\nepisode: {episode}\nshot: {shot}\n")
        new_folder = Path(PROJECTS) / f"{episode}-{shot}"
    else:
        print(f"parent folder: {PROJECTS}\nshot: {shot}\n")
        new_folder = Path(PROJECTS) / shot

    try:
        Path.mkdir(new_folder, parents=True, exist_ok=False)
    except FileExistsError:
        print("comp folder already exists")
    else:
        print(f"folder {new_folder} is created!")
    return new_folder


def save_comp(folder, episode, shot) -> int:
    """build comp path and, if the comp exists, up version, then run update_savers"""

    comp_version = 1
    while True:
        if PARSE_EPISODES:
            new_comp = (folder / f"{PROJECT_SHORT}_{episode}_{shot}_{AUTHOR}_v{comp_version:02d}.comp")
        else:
            new_comp = (folder / f"{PROJECT_SHORT}_{shot}_{AUTHOR}_v{comp_version:02d}.comp")
        if not new_comp.exists():
            break
        comp_version += 1

    comp.Save(str(new_comp))
    return comp_version


def update_savers(version, episode, shot):

    savers = comp.GetToolList(False, "Saver").values()
    if not savers:
        print("No savers found in comp")
        return

    comp.StartUndo("Set Saver files")
    for saver in savers:
        saver_clip = Path(saver.Clip[1])
        parent = saver_clip.parent
        elements = re.split("[.|_]", saver_clip.name)
        ext = saver_clip.suffix

        if PARSE_EPISODES:
            new_path = Path(
                rf"{parent}/{PROJECT_SHORT}_{episode}_{shot}_v{version:02d}{ext}"
            )
        else:
            new_path = Path(rf"{parent}/{PROJECT_SHORT}_{shot}_v{version:02d}{ext}")
        print(f"new saver path: {comp.MapPath(str(new_path))}")
        saver.Clip[1] = str(new_path)
    comp.EndUndo()
    return saver_clip.stem


def set_range(loader) -> None:
    """set GlobalIn and GlobalOut according to Loader clip length"""

    comp.StartUndo("Set Range based on Loader")
    clip_in = loader.GlobalIn[1]
    clip_out = loader.GlobalOut[1]
    comp.SetAttrs({"COMPN_GlobalStart": clip_in})
    comp.SetAttrs({"COMPN_GlobalEnd": clip_out})
    comp.EndUndo()
    print(f"Comp length is adjusted to [ {clip_in} - {clip_out} ]")


def main():

    loader = get_loader()
    
    if not loader:
        return

    episode, shot = parse_loader(loader)

    if not shot:
        print("comp not parsed")
        return

    new_folder = create_comp_folder(episode, shot)

    comp_version = save_comp(new_folder, episode, shot)

    comp_name = update_savers(comp_version, episode, shot)

    set_range(loader)


if __name__ == "__main__":
    main()
