#!/usr/bin/env python

"""
    Set new Comp from Loader
    
    License:
    Copyright © 2024 Alexey Bogomolov (mail@abogomolov.com)
    VESION: 1.0

"""

import re
from pathlib import Path
from fusion_comp_utils import CompUtils
from datetime import datetime


comp = fu.GetCurrentComp()
comp_utils = CompUtils(comp)

COMP_FOLDER = "fusion"
AUTHOR = "ab"
COMP_VERSION = 1
INCREMENT_COMP = False

def get_date():
    """Get the current date in YYMMDD format"""
    current_date = datetime.now()
    formatted_date = current_date.strftime('%y%m%d')
    return formatted_date


def create_comp_folder(folder):
    """build comp folder from the parsed loader data"""

    print(f"parent folder: {folder}")

    new_folder = Path(folder) / COMP_FOLDER
    try:
        Path.mkdir(new_folder, parents=True, exist_ok=False)
    except FileExistsError:
        print("comp folder already exists")
    else:
        print(f"folder {new_folder} is created!")
    return new_folder


def update_savers(version, comp_name):
    savers = comp.GetToolList(False, "Saver").values()
    if not savers:
        print("No savers found in comp")
        return
    comp.StartUndo("Set Saver Paths")
    current_date = get_date()
    for saver in savers:
        path = Path(saver.Clip[1])
        parent = path.parent.parent
        ext = Path(path).suffix
        new_path = Path(rf"{parent}/RENDERS/{current_date}/{comp_name}{ext}")
        print(f"New saver path: {new_path}")
        saver.Clip[1] = str(new_path)
    comp.EndUndo()


def generate_comp_name(file_name: str, author: str, version: int) -> str:
    """Generate a composition file name."""
    return f"{file_name}_{author}_v{version:02d}"


def save_comp(folder: Path, file_stem: str, author: str, comp_version=1) -> int:
    """Build comp name and path, and save the comp."""
    try:
        if not folder.exists():
            folder.mkdir(parents=True, exist_ok=True)

        version = comp_version
        comp_name = generate_comp_name(file_stem, author, version)
        new_comp = folder / f"{comp_name}.comp"

        if INCREMENT_COMP:
            while new_comp.exists():
                version += 1
                comp_name = generate_comp_name(file_stem, author, version)
                new_comp = folder / f"{comp_name}.comp"

        comp.Save(str(new_comp))
        update_savers(version, comp_name)

        return version

    except Exception as e:
        print(f"An error occurred: {e}")
        return -1


def get_safe_folder_path(path, comp_folder, folder_levels=3):
    # Ensure path is a Path object
    path = Path(path)

    # Check if path has at least three parents
    if len(path.parents) >= folder_levels:
        folder = path.parents[2] / comp_folder
    else:
        raise ValueError("Path does not have enough parent directories.")

    return folder


def main():

    loader = comp_utils.get_loader()
    if not loader:
        return
    comp_utils.set_range(loader)
    path = comp_utils.parse_loader_path(loader)
    stem = path.stem
    
    folder = get_safe_folder_path(path, COMP_FOLDER)

    if not folder:
        print("Comp not parsed")
        return

    save_comp(folder, stem, AUTHOR)


if __name__ == "__main__":
    main()
