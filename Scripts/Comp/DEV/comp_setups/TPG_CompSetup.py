#!/usr/bin/env python

"""
    Set new Comp from Loader
    
    License:
    Copyright © 2024 Alexey Bogomolov (mail@abogomolov.com)
    VESION: 1.0

"""

from pathlib import Path
from fusion_comp_utils import CompUtils
from datetime import datetime
from resolve_utils import set_logging
from UI_utils import WarningDialog
import DaVinciResolveScript as drs


LOG_LEVEL = "debug"

log = set_logging(level=LOG_LEVEL, script_name="TPG Comp Setup")

fu = drs.scriptapp("Fusion")
comp = fu.GetCurrentComp()
comp_utils = CompUtils(comp)

COMP_FOLDER = "FUSION"
AUTHOR = "ab"
COMP_VERSION = 1
INCREMENT_COMP = True


def get_date():
    """Get the current date in YYMMDD format"""
    current_date = datetime.now()
    formatted_date = current_date.strftime("%y%m%d")
    return formatted_date


def create_comp_folder(folder):
    """build comp folder from the parsed loader data"""

    log.debug(f"parent folder: {folder}")

    new_folder = Path(folder) / COMP_FOLDER
    try:
        Path.mkdir(new_folder, parents=True, exist_ok=False)
    except FileExistsError:
        log.debug("comp folder already exists")
    else:
        log.debug(f"folder {new_folder} is created!")
    return new_folder


def update_savers(comp_path: Path):
    savers = comp.GetToolList(False, "Saver").values()
    if not savers:
        log.debug("No savers found in comp")
        return
    comp.StartUndo("Set Saver Paths")
    current_date = get_date()


    # Find the parent of the "FOOTAGE" folder
    project_folder = None
    for parent_folder in comp_path.parents:
        if parent_folder.name == "FUSION":
            project_folder = parent_folder.parent
            break
        else:
            log.error("Could not find the FOOTAGE folder. Check the Loader path")
            comp.EndUndo()
            return
    comp_name = comp_path.stem

    for saver in savers:
        path = Path(saver.Clip[1])
        ext = Path(path).suffix or ".mov"
        if ext == ".exr":
            comp_path += "."
        # we already have verion number in the comp_name
        new_path = Path(f"{project_folder}/RENDERS/{current_date}/{comp_name}{ext}")
        log.debug(f"New saver path: {new_path}")
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
        new_comp_path = folder / f"{comp_name}.comp"

        if INCREMENT_COMP:
            while new_comp_path.exists():
                version += 1
                comp_name = generate_comp_name(file_stem, author, version)
                new_comp_path = folder / f"{comp_name}.comp"

        comp.Save(str(new_comp_path))
        update_savers(new_comp_path)

        return version

    except Exception as e:
        log.error(f"An error occurred: {e}")
        return -1


def get_save_folder(path, comp_folder, folder_levels=3):
    # Ensure path is a Path object
    path = Path(path)
    if path.suffix in [".exr", ".dpx", ".png", ".jpg"]:
        folder_levels += 1
    # Check if path has at least three parents
    if len(path.parents) >= folder_levels:
        folder = path.parents[folder_levels-1] / comp_folder
    else:
        raise ValueError("Path does not have enough parent directories.")

    return folder


def main():

    loader = comp_utils.get_loader()
    comp.Lock()
    comp.SetActiveTool(loader)
    comp.AddTool("Saver",  -32768, -32768)
    comp.Unlock()
    if not loader:
        return
    comp_utils.set_range(loader)
    loader_path = comp_utils.get_loader_path(loader)
    if not loader_path.exists():
        message = "The Loader path does not exist"
        WarningDialog(message)
        log.error(message)
        return
    loader_stem = loader_path.stem

    comp_save_folder = get_save_folder(loader_path, COMP_FOLDER)
    log.info(f"Comp folder: {comp_save_folder}")

    if not comp_save_folder:
        log.warning("Could not get save folder")
        return

    save_comp(comp_save_folder, loader_stem, AUTHOR)


if __name__ == "__main__":
    main()
