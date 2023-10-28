from pathlib import Path
from grab_still import get_still_album, get_target_folder
from resolve_utils import (
    request_dir,
    get_timeline_and_gallery,
    confirmation_dialogue,
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
STILL_ALBUM = "gal22"
FORMAT = "png"
DELETE_STILLS = True
OPEN_EDIT_PAGE_AFTER_EXPORT = False
CLEANUP_DRX = True


def post_processing(stills: list, still_album, target_folder=None):
    if DELETE_STILLS:
        still_album_name = gallery.GetAlbumName(still_album)
        print(
            f"Please note, that DELETE_STILLS is set to True, so new stills in '{still_album_name}' album will be erased"
        )
        answer = confirmation_dialogue(
            "Stills Deletion!",
            f"Do you want to delete stills\nin '{still_album_name}' album?",
        )
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

    timeline_name = timeline.GetName()
    video_track_count = timeline.GetTrackCount("video")

    print(f"Found {video_track_count} tracks")

    still_album = get_still_album(gallery, STILL_ALBUM)
    still_album_name = gallery.GetAlbumName(still_album)
    stills = timeline.GrabAllStills(STILL_FRAME_REF)

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
    post_processing(stills, still_album, target_folder)


if __name__ == "__main__":
    timeline, gallery = get_timeline_and_gallery(resolve)
    grab_timeline_stills()
