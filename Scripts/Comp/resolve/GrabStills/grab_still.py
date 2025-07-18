"""
    This is a Davinci Resolve script to save single still in predefined folder

    License: MIT
    Copyright © 2024 Alexey Bogomolov
    Email: mail@abogomolov.com
    
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

from datetime import datetime
from pathlib import Path
from resolve_utils import ResolveUtility, get_app

from ui_utils import (
    RequestDir,
    ConfirmationDialog,
)
from log_utils import set_logging

log = set_logging()

utils = ResolveUtility()
fusion = get_app("Fusion")

STILL_ALBUM = "STILLS"
DELETE_STILLS = True
OPEN_EDIT_PAGE_AFTER_EXPORT = True
CLEANUP_DRX = True
CONFIRM_DELETE = False
STILL_FORMAT = "png"


def get_target_folder() -> str:
    """
    Checks for target folder Resolve data,
    Shows folder request dialogue if data not found
    """
    target_folder_data = fusion.GetData("ResolveSaveStills.Folder")
    if not target_folder_data or target_folder_data == "":
        target_folder = RequestDir("The stills will be saved to: ", target_folder_data)
        fusion.SetData("ResolveSaveStills.Folder", target_folder)
        return target_folder

    return target_folder_data


def get_still_file(folder, still_filename: Path) -> Path:
    for file in folder.iterdir():
        if file.suffix == f".{STILL_FORMAT}" and file.name.startswith(still_filename.stem):
            return file


def remove_drx_file(still_filepath: Path):
    log.debug("CLEANUP_DRX is enabled")
    answer = True
    if CONFIRM_DELETE:
        answer = ConfirmationDialog(
            title="DRX files deletion!",
            request="Do you wish to delete the DRX file?",
        )
    if answer:
        try:
            still_filepath.unlink()
        except Exception:
            raise


def get_file_prefix(clip_name, timeline_name):
    now = datetime.now()
    date_time = now.strftime("%m%d%Y")
    file_prefix = f"{clip_name}_{date_time}_{timeline_name}"
    return file_prefix


def post_processing(still, still_album, target_folder, file_prefix):

    still_filename = f"{file_prefix}.{STILL_FORMAT}"
    still_file = get_still_file(target_folder, Path(still_filename))
    if isinstance(still_file, Path):
        log.debug(f"Found still file: {still_file.name}")
        utils.add_to_mediapool(
            [still_file.as_posix()]
        )

    if CLEANUP_DRX:
        # log.debug(f"Cleaning the drx file for {still_label}")
        drx_file = still_file.with_suffix(".drx")
        remove_drx_file(drx_file)

    if DELETE_STILLS:
        log.debug("DELETE_STILLS is enabled, latest still is deleted from the still album")
        still_album.DeleteStills(still)

    if OPEN_EDIT_PAGE_AFTER_EXPORT:
        utils.resolve.OpenPage("edit")


def grab_still(album_name: str):
    """
    create still from current position on the timeline
    save the files to the predefined folder
    """

    if not utils.resolve:
        log.debug("This is a script for Davinci Resolve")
        return
    current_timeline = utils.get_current_timeline()
    current_clip_name = current_timeline.GetCurrentVideoItem().GetName()
    timeline_name = current_timeline.GetName()

    file_prefix = get_file_prefix(current_clip_name, timeline_name)
    gallery = utils.get_gallery()

    still_album = utils.get_still_album(gallery, STILL_ALBUM)

    if not still_album:
        return
    still_album_name = gallery.GetAlbumName(still_album)
    target_folder = get_target_folder()
    if not target_folder:
        log.debug("Target folder is not set, aborting script.")
        return
    target_folder = Path(target_folder, still_album_name)
    if not target_folder.exists():
        utils.create_folder(target_folder)
    still = current_timeline.GrabStill()
    still_album.SetLabel(still, current_clip_name)
    log.debug(f"Exporting:\ntarget_folder:{target_folder}\nfile_prefix:{file_prefix}")
    still_album.ExportStills(
        [still], target_folder.as_posix(), file_prefix, STILL_FORMAT
    )
    log.debug(f"Still is saved to {target_folder}")
    post_processing(still, still_album, target_folder, file_prefix)


if __name__ == "__main__":
    grab_still(album_name=STILL_ALBUM)
