from pathlib import Path
import time
from resolve_utils import ResolveUtility
from ui_utils import (
    ConfirmationDialog, RequestDir
)

"""
    This is a Davinci Resolve script to save all timeline clips to images.

    License: MIT
    Copyright © 2024 Alexey Bogomolov
    Email: mail@abogomolov.com
"""

STILL_FRAME_REF = 2  # 1 - First frame, 2 - Middle frame
STILL_ALBUM = "STILLS"
STILL_FORMAT = "jpg"
DELETE_STILLS = True
OPEN_EDIT_PAGE_AFTER_EXPORT = True
CLEANUP_DRX = True
SAVE_PER_MARKER = True  # True - save per marker, False - save per clip

utils = ResolveUtility()
resolve = utils.resolve
fusion = resolve.Fusion()


def get_target_folder() -> str:
    """
    Checks for target folder Resolve data,
    Shows folder request dialogue if data not found
    """
    target_folder_data = fusion.GetData("BatchResolveSaveStills.Folder")
    if not target_folder_data or target_folder_data == "":
        target_folder = RequestDir("The stills will be saved to: ", target_folder_data)
        fusion.SetData("BatchResolveSaveStills.Folder", target_folder)
        return target_folder

    return target_folder_data



def cleanup_drx_from_folder(folder: Path):
    print(
        "CLEANUP DRX is enabled, all .drx files in the stills location will be erased"
    )
    answer = ConfirmationDialog(
        title="DRX files deletion!",
        request=f"Do you wish to delete all DRX files\nin'{folder}' folder?",
    )

    if answer:
        for file in folder.iterdir():
            if file.suffix == ".drx":
                file.unlink()


def post_processing(stills: list, still_album, gallery, target_folder=None):
    if DELETE_STILLS:
        still_album_name = gallery.GetAlbumName(still_album)
        print(
            f"Please note, that DELETE_STILLS is set to True, so new stills in '{still_album_name}' album will be erased"
        )
        answer = ConfirmationDialog(
            "Stills Deletion!",
            f"Do you want to delete stills\nin '{still_album_name}' album?",
        )
        if answer:
            still_album.DeleteStills(stills)

    if CLEANUP_DRX:
        cleanup_drx_from_folder(target_folder)

    if OPEN_EDIT_PAGE_AFTER_EXPORT:
        utils.resolve.OpenPage("edit")


def grab_stills_from_markers(current_timeline, still_album):
    """Create stills from timeline markers"""
    markers = current_timeline.GetMarkers()
    if not markers:
        print("No markers found in timeline")
        return []
    
    stills = []
    for frame_id, marker_data in markers.items():
        current_timeline.SetCurrentTimecode(utils.frame_to_timecode(frame_id))
        print(f"Processing marker at timecode: {current_timeline.GetCurrentTimecode()}")
        time.sleep(1)  # Adding a small delay to ensure the still is captured correctly
        still = current_timeline.GrabStill()
        marker_name = marker_data.get('name', 'Unnamed')
        still_album.SetLabel(still, marker_name)
        print(f"Grabbed still from marker at frame {frame_id}: {marker_name}")
        stills.append(still)

    if stills:
        updated_stills = still_album.GetStills()
        return updated_stills
    return []

def grab_timeline_stills(delete_stills=False):
    """create stills from all clips in a timeline or from markers
    save the files to requested folder. Currently GetGalleryStillAlbums() is used,
    so we are unable to add a label to each still.
    """
    if not utils.resolve:
        print("This is a script for Davinci Resolve")
        return

    gallery = utils.get_gallery()

    current_timeline = utils.get_current_timeline()
    timeline_name = current_timeline.GetName()
    video_track_count = current_timeline.GetTrackCount("video")

    print(f"Found {video_track_count} tracks")

    still_album = utils.get_still_album(gallery, STILL_ALBUM)
    still_album_name = gallery.GetAlbumName(still_album)
    
    if SAVE_PER_MARKER:
        print("Saving stills per marker")
        stills = grab_stills_from_markers(current_timeline, still_album)
    else:
        print("Saving stills per clip")
        stills = current_timeline.GrabAllStills(STILL_FRAME_REF)

    if len(stills) == 0:
        print("No stills saved")
        return

    target_folder = get_target_folder()
    if not target_folder:
        print("Target folder is not set, aborting script.")
        return

    target_folder = Path(target_folder, still_album_name)
    folder = utils.create_folder(target_folder)
    if not folder:
        utils.reset_global_data("ResolveSaveStills.Folder")

    print(f"Saving stills to {target_folder}")

    still_album.ExportStills(
        stills, target_folder.as_posix(), timeline_name, STILL_FORMAT
    )
    post_processing(stills, still_album, gallery, target_folder)


if __name__ == "__main__":
    grab_timeline_stills()
