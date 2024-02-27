from pathlib import Path
from grab_still import get_still_album, get_target_folder
from resolve_utils import (
    get_current_timeline,
    get_gallery,
    ConfirmationDialog,
    create_folder,
    cleanup_drx,
)

"""
    This is a Davinci Resolve script to save all timeline clips to images.

    License: MIT
    Copyright © 2023 Alexey Bogomolov
    Email: mail@abogomolov.com
"""

STILL_FRAME_REF = 2
STILL_ALBUM = "Export"
FORMAT = "png"
DELETE_STILLS = True
OPEN_EDIT_PAGE_AFTER_EXPORT = True
CLEANUP_DRX = True


def post_processing(stills: list, still_album, gallery, target_folder=None):
    if DELETE_STILLS:
        still_album_name = gallery.GetAlbumName(still_album)
        print(
            f"Please note, that DELETE_STILLS is set to True, so new stills in '{still_album_name}' album will be erased"
        )
        dialog = ConfirmationDialog(
            fu,
            "Stills Deletion!",
            f"Do you want to delete stills\nin '{still_album_name}' album?",
        )
        answer = dialog.run()
        if answer:
            still_album.DeleteStills(stills)

    if CLEANUP_DRX:
        cleanup_drx(target_folder)

    if OPEN_EDIT_PAGE_AFTER_EXPORT:
        resolve.OpenPage("edit")


def grab_timeline_stills(delete_stills=False):
    """create stills from all clips in a timeline
    save the files to requested folder. Currently GetGalleryStillAlbums() is used,
    so we are unable to add a label to each still.
    """
    if not app.GetResolve():
        print("This is a script for Davinci Resolve")
        return

    gallery = get_gallery(resolve)

    current_timeline = get_current_timeline(resolve)
    timeline_name = current_timeline.GetName()
    video_track_count = current_timeline.GetTrackCount("video")

    print(f"Found {video_track_count} tracks")

    still_album = get_still_album(gallery, STILL_ALBUM)
    still_album_name = gallery.GetAlbumName(still_album)
    stills = current_timeline.GrabAllStills(STILL_FRAME_REF)

    if len(stills) == 0:
        print("No stills saved")
        return

    target_folder = get_target_folder(fusion)
    if not target_folder:
        print("Target folder is not set, aborting script.")
        return

    target_folder = Path(target_folder, still_album_name)
    create_folder(target_folder)

    print(f"Saving stills to {target_folder}")

    still_album.ExportStills(stills, target_folder.as_posix(), timeline_name, FORMAT)
    post_processing(stills, still_album, gallery, target_folder)


if __name__ == "__main__":
    grab_timeline_stills()
