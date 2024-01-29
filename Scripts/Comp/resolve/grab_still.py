import os
from datetime import datetime
from pathlib import Path
from resolve_utils import (
    get_timeline_and_gallery,
    confirmation_dialogue,
    request_dir,
    create_folder,
    cleanup_drx,
)
from typing import TypeVar

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
STILL_FRAME_REF = 1
STILL_ALBUM = "gal22"
DELETE_STILLS = True
OPEN_EDIT_PAGE_AFTER_EXPORT = False
CLEANUP_DRX = True
galleryStillAlbum = TypeVar("galleryStillAlbum")


def get_target_folder(app) -> str:
    """
    Checks for target folder Resolve data,
    Shows folder request dialogue if data not found
    """
    target_folder_data = app.GetData("ResolveSaveStills.Folder")
    if not target_folder_data or target_folder_data == "":
        target_folder = request_dir("The stills will be saved to: ", target=target_folder_data)
        return target_folder

    return target_folder_data


def get_still_album(gallery, album_name: str) -> galleryStillAlbum:
    still_album = None
    albums = gallery.GetGalleryStillAlbums()
    for album in albums:
        if gallery.GetAlbumName(album) == album_name:
            gallery.SetCurrentStillAlbum(album)
            still_album = gallery.GetCurrentStillAlbum()
    if not still_album:
        print(
            f"Stills album '{album_name}' not found. Currently I'm unable to can create the still albums for you. Would you do this manually, please?"
        )
        print("The stills will be saved to the currently selected album")

        still_album = gallery.GetCurrentStillAlbum()
    return still_album


def get_file_prefix(clip_name, timeline_name):
    now = datetime.now()
    date_time = now.strftime("%m%d%Y")
    file_prefix = f"{clip_name}_{date_time}_{timeline_name}"
    return file_prefix


def post_processing(still, still_album, target_folder):
    if DELETE_STILLS:
        print("DELETE_STILLS is enabled, latest still will is deleted")
        still_album.DeleteStills(still)

    if CLEANUP_DRX:
        cleanup_drx(target_folder)

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
    current_clip_name = timeline.GetCurrentVideoItem().GetName()
    timeline_name = timeline.GetName()

    file_prefix = get_file_prefix(current_clip_name, timeline_name)

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
        create_folder(target_folder)
    still = timeline.GrabStill(STILL_FRAME_REF)
    still_album.SetLabel(still, current_clip_name)
    still_album.ExportStills([still], target_folder.as_posix(), file_prefix, "png")
    print(f"Still is saved to {target_folder}")
    post_processing(still, still_album, target_folder)


if __name__ == "__main__":
    timeline, gallery = get_timeline_and_gallery(resolve)
    grab_still(album_name=STILL_ALBUM)
