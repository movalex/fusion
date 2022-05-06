#!/usr/bin/env python

"""
    Set new comp from template
    New comp will ve created in COMP_FOLDER location,
    with episode_shot_author_version.comp format (106_0055_ab_v01.comp).
    
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

import re
from pathlib import Path

comp = fu.GetCurrentComp()
COMP_FOLDER = "FUSION"
AUTHOR = "ab"
COMP_VERSION = 1


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
        episode, shot = re.search("(\d{3})_(\d{4})", parse_name).groups()
        # _, episode, shot = parse_name.split("_")
    except ValueError:
        return
    folder = loader_path.parents[3]
    return folder, episode, shot


def create_comp_folder(folder, episode, shot):
    """build comp folder from the parsed loader data"""

    print(f"parent folder: {folder}\nepisode: {episode}\nshot: {shot}\n")

    new_folder = Path(folder) / COMP_FOLDER / f"{episode}-{shot}"
    try:
        Path.mkdir(new_folder, parents=True, exist_ok=False)
    except FileExistsError:
        print("comp folder already exists")
    else:
        print(f"folder {new_folder} is created!")
    return new_folder


def update_savers(version, episode, shot):

    savers = comp.GetToolList(False, "Saver").values()
    if not savers:
        print("No savers found in comp")
        return

    comp.StartUndo("Set Shot Nums")
    for saver in savers:
        path = saver.Clip[1]
        parent = Path(path).parent
        ext = Path(path).suffix
        new_path = Path(rf"{parent}/{episode}_{shot}_v{version:02d}{ext}")
        print(f"new saver path: {new_path}")
        saver.Clip[1] = str(new_path)
    comp.EndUndo()


def save_comp(folder, episode, shot) -> int:
    """build comp name and path and save the comp"""

    new_folder = create_comp_folder(folder, episode, shot)

    comp_version = COMP_VERSION
    new_comp = new_folder / f"{episode}_{shot}_{AUTHOR}_v{comp_version:02d}.comp"
    while new_comp.exists():
        comp_version += 1
        new_comp = new_folder / f"{episode}_{shot}_{AUTHOR}_v{comp_version:02d}.comp"

    comp.Save(str(new_comp))

    update_savers(comp_version, episode, shot)


def set_range(loader) -> None:
    """set GlobalIn and GlobalOut according to Loader clip length"""

    comp.StartUndo("Set Range based on Loader")
    loader_attrs = loader.GetAttrs()

    clip_in = loader.GlobalIn[1]
    trim_start = loader_attrs["TOOLIT_Clip_TrimIn"][1]

    clip_out = loader.GlobalOut[1]
    trim_end = loader_attrs["TOOLIT_Clip_TrimOut"][1]
    if trim_start == clip_in:
        comp.SetAttrs({"COMPN_GlobalStart": clip_in})
        comp.SetAttrs({"COMPN_RenderStart": clip_in})
    else:
        comp.SetAttrs({"COMPN_GlobalStart": clip_in})
        comp.SetAttrs({"COMPN_RenderStart": trim_start})
        clip_in = trim_start

    if trim_end == clip_out:
        comp.SetAttrs({"COMPN_GlobalEnd": clip_out})
        comp.SetAttrs({"COMPN_RenderEnd": clip_out})
    else:
        comp.SetAttrs({"COMPN_GlobalStart": clip_in})
        comp.SetAttrs({"COMPN_RenderStart": trim_end})
        clip_out = trim_end

    comp.EndUndo()
    print(f"Comp length is adjusted to [ {clip_in} - {clip_out} ]")


def main():

    loader = get_loader()
    if not loader:
        return

    set_range(loader)

    folder, episode, shot = parse_loader_path(loader)
    if not episode:
        print("comp not parsed")
        return

    save_comp(folder, episode, shot)


if __name__ == "__main__":
    main()
