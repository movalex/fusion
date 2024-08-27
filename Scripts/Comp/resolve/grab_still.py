"""
    This is a Davinci Resolve script to save single still in predefined folder

    License: MIT
    Copyright © 2023 Alexey Bogomolov
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

import os
import DaVinciResolveScript as dvr_script
from datetime import datetime
from pathlib import Path
from resolve_utils import ResolveUtility

from UI_utils import (
    RequestDir,
    ConfirmationDialog,
)
from typing import TypeVar


resolve = dvr_script.scriptapp("Resolve")
utils = ResolveUtility(resolve)

STILL_ALBUM = "STILLS"
DELETE_STILLS = True
OPEN_EDIT_PAGE_AFTER_EXPORT = True
CLEANUP_DRX = True
STILL_FORMAT = "png"
galleryStillAlbum = TypeVar("galleryStillAlbum")


def get_target_folder(app) -> str:
    """
    Checks for target folder Resolve data,
    Shows folder request dialogue if data not found
    """
    target_folder_data = app.GetData("ResolveSaveStills.Folder")
    if not target_folder_data or target_folder_data == "":
        target_folder = RequestDir("The stills will be saved to: ", target_folder_data)
        return target_folder

    return target_folder_data


def get_drx_file(folder, still_filename: Path) -> Path:
    for file in folder.iterdir():
        if file.suffix == ".drx" and file.name.startswith(still_filename.stem):
            return file


def remove_drx_file(still_filepath: Path):
    print("CLEANUP_DRX is enabled")

    answer = ConfirmationDialog(
        title="DRX files deletion!",
        request=f"Do you wish to delete this files\n'{still_filepath.name}'?",
    )
    if answer:
        try:
            still_filepath.unlink()
        except Exception:
            raise


def get_still_album(gallery, album_name: str) -> galleryStillAlbum:
    still_album = None
    albums = gallery.GetGalleryStillAlbums()
    for album in albums:
        if gallery.GetAlbumName(album) == album_name:
            gallery.SetCurrentStillAlbum(album)
            still_album = gallery.GetCurrentStillAlbum()
    if not still_album:
        print(
            f"Default still album '{album_name}' is not found. Please create this album if you want to store screenshots in specific album"
        )
        print(
            "The stills will be saved to the currently selected album or the first available"
        )

        still_album = gallery.GetCurrentStillAlbum()
    return still_album


def get_file_prefix(clip_name, timeline_name):
    now = datetime.now()
    date_time = now.strftime("%m%d%Y")
    file_prefix = f"{clip_name}_{date_time}_{timeline_name}"
    return file_prefix


def post_processing(still, still_album, target_folder, file_prefix):

    still_label = Path(still_album.GetLabel(still))
    still_filename = f"{file_prefix}.{STILL_FORMAT}"
    file_path = Path(target_folder) / still_filename
    drx_file = get_drx_file(target_folder, Path(still_filename))
    utils.add_to_mediapool(
        [drx_file.with_suffix(f".{STILL_FORMAT}").as_posix()],
        subfolder_name=STILL_ALBUM,
    )

    if CLEANUP_DRX:
        # print(f"Cleaning the drx file for {still_label}")
        remove_drx_file(drx_file)

    if DELETE_STILLS:
        print("DELETE_STILLS is enabled, latest still is deleted from the still album")
        still_album.DeleteStills(still)

    if OPEN_EDIT_PAGE_AFTER_EXPORT:
        resolve.OpenPage("edit")


def grab_still(album_name: str):
    """
    create still from current position on the timeline
    save the files to the predefined folder
    """
    if not fu.GetResolve():
        print("This is a script for Davinci Resolve")
        return
    current_timeline = utils.get_current_timeline()
    current_clip_name = current_timeline.GetCurrentVideoItem().GetName()
    timeline_name = current_timeline.GetName()

    file_prefix = get_file_prefix(current_clip_name, timeline_name)
    gallery = utils.get_gallery()

    still_album = get_still_album(gallery, STILL_ALBUM)

    if not still_album:
        return
    still_album_name = gallery.GetAlbumName(still_album)
    target_folder = get_target_folder(fusion)
    if not target_folder:
        print("Target folder is not set, aborting script.")
        return
    target_folder = Path(target_folder, still_album_name)
    if not target_folder.exists():
        utils.create_folder(target_folder)
    still = current_timeline.GrabStill()
    still_album.SetLabel(still, current_clip_name)
    print(f"Exporting:\ntarget_folder:{target_folder}\nfile_prefix:{file_prefix}")
    still_album.ExportStills(
        [still], target_folder.as_posix(), file_prefix, STILL_FORMAT
    )
    print(f"Still is saved to {target_folder}")
    post_processing(still, still_album, target_folder, file_prefix)


if __name__ == "__main__":
    grab_still(album_name=STILL_ALBUM)
