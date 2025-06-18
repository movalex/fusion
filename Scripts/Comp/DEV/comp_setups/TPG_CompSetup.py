#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Set new Comp from Loader

This script sets up a new Fusion composition based on the selected Loader node
Copyright © 2025 Alexey Bogomolov
VERSION: 1.2
"""

from pathlib import Path
from fusion_comp_utils import CompUtils
from datetime import datetime
from resolve_utils import set_logging
from UI_utils import WarningDialog, RequestDir
from itertools import count
import BlackmagicFusion as bmd
fusion = bmd.scriptapp("Fusion")


LOG_LEVEL = "debug"

log = set_logging(level=LOG_LEVEL, script_name="TPG Comp Setup")

comp = fusion.GetCurrentComp()
comp_utils = CompUtils(comp)
script_name = "tpg_comp_setup"
COMP_FOLDER = "FUSION"
AUTHOR = "ab"
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


def update_saver(saver, save_path: Path, comp_path: str):
    comp.StartUndo("Set Saver Path")
    current_date = get_date()
    file_name = comp_path.stem
    ext = ".mov"
    # we already have version number and author in the file_name
    new_path = Path(f"{save_path}/{current_date}/{file_name}{ext}")
    log.debug(f"New saver path: {new_path}")
    saver.Clip[1] = str(new_path)
    comp.EndUndo()


def generate_comp_name(file_name: str, author: str, version: int) -> str:
    """Generate a composition file name."""
    return f"{file_name}_{author}_v{version:02d}"


def get_next_available_comp_path(folder: Path, file_stem: str, author: str, start_version: int) -> tuple[Path, int]:
    """
    Find the next available comp path by incrementing version if needed.

    If INCREMENT_COMP is True, increments the version number until a non-existing file is found.
    If INCREMENT_COMP is False, returns the path for start_version (default 1) regardless of file existence,
    which may result in overwriting an existing file.
    """
    for version in count(start_version):
        comp_name = generate_comp_name(file_stem, author, version)
        comp_path = folder / f"{comp_name}.comp"
        if not comp_path.exists() or not INCREMENT_COMP:
            return comp_path, version


def save_comp(folder: Path, file_stem: str, author="ab", comp_version=1) -> Path:
    """
    Build comp name and path, and save the comp.

    Uses get_next_available_comp_path to determine the file path:
    - If INCREMENT_COMP is True, will increment version to avoid overwriting.
    - If INCREMENT_COMP is False, will use the initial version and may overwrite existing files.

    Returns the saved comp path or None on error.
    """
    try:
        folder.mkdir(parents=True, exist_ok=True)
        comp_path, _ = get_next_available_comp_path(folder, file_stem, author, comp_version)
        comp.Save(str(comp_path))
        return comp_path
    except Exception as e:
        log.error(f"An comp save error occurred: {e}")
        return None


def request_saver_folder(path):
    # Ensure path is a Path object
    
    save_folder = RequestDir("Choose Saver output folder", str(path))
    return Path(save_folder) if save_folder else None

def request_comp_folder(default_folder=None):
    """
    Prompt the user to select a folder to save the Fusion comp.
    Returns a Path object or None if cancelled.
    """
    if default_folder is None:
        default_folder = str(Path.home())
    folder = RequestDir("Select folder to save Fusion comp", str(default_folder))
    
    return Path(folder) if folder else None



def create_empty_saver(loader):
    comp.Lock()
    comp.SetActiveTool(loader)
    saver_node = comp.AddTool("Saver", -32768, -32768)
    comp.Unlock()
    flow = comp.CurrentFrame.FlowView
    flow.Select()
    return saver_node


def process_loader(comp_utils):
    loader = comp_utils.get_selected_loader()
    if not loader:
        message = "No Loader selected. Please select a Loader node."
        log.error(message)
        WarningDialog(message)
        return None, None, None
    comp_utils.set_range(loader)
    loader_path = comp_utils.get_loader_path(loader)

    if not loader_path.exists():
        message = "The Loader path does not exist"
        WarningDialog(message)
        log.error(message)
        return None, None, None
    log.info(f"Loader path: {loader_path}")
    loader_stem = loader_path.stem

    return loader, loader_path, loader_stem

def choose_folders(loader_path):
    # Recall last used folder from fusion.GetData
    last_comp_folder = fusion.GetData(f"{script_name}.last_comp_save_folder")
    last_output = fusion.GetData(f"{script_name}.last_comp_output")
    log.debug(f"Last used folder: {last_comp_folder}")
    log.debug(f"Last used output: {last_output}")
    if last_comp_folder and Path(last_comp_folder).exists():
        suggest_comp_folder = Path(last_comp_folder)
    else:
        suggest_comp_folder = loader_path.parent
    
    if last_output and Path(last_output).exists():
        suggest_output = Path(last_output)
    else:
        suggest_output = loader_path.parent


    # Prompt user for save folder, default to last used or suggested folder
    saver_folder = request_saver_folder(suggest_output)
    if not saver_folder:
        log.warning("User cancelled saver folder selection")
        return None, None
    # Use default_folder as argument
    comp_save_folder = request_comp_folder(suggest_comp_folder)
    if not comp_save_folder:
        log.warning("User cancelled comp folder selection")
        return None, None
    return saver_folder, comp_save_folder

def run_saver_and_save_comp(loader, comp_save_folder, saver_folder, loader_stem):
    saver = create_empty_saver(loader)

    comp_path = save_comp(comp_save_folder, loader_stem)
    update_saver(saver, saver_folder, comp_path)
    log.info(f"Comp path: {comp_path}")
    if not comp_path:
        WarningDialog("Failed to save comp. See log for details.")
        return None
    log.info(f"Comp saved: {comp_path}")
    fusion.SetData(f"{script_name}.last_comp_save_folder", str(comp_save_folder))
    fusion.SetData(f"{script_name}.last_comp_output", str(saver_folder))
    return comp_path

def main():
    loader, loader_path, loader_stem = process_loader(comp_utils)
    if not loader:
        return
    saver_folder, comp_save_folder = choose_folders(loader_path)
    if not saver_folder or not comp_save_folder:
        return
    comp_path = run_saver_and_save_comp(loader, comp_save_folder, saver_folder, loader_stem)
    if not comp_path:
        WarningDialog("Failed to save comp. See log for details.")
        return

if __name__ == "__main__":
    main()
