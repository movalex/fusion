import os
from datetime import datetime

"""
    This is a Davinci Resolve script to save single still in stills folder
    Email: mail@abogomolov.com
    Copyright © 2022 Alexey Bogomolov
    
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
STILL_FRAME_REF = 2
EXPORT_ALBUM = "export_30.04"


def get_target_folder():
    target_folder = fu.GetData("ResolveSaveStills.Folder")
    if not target_folder or target_folder == " ":
        target_folder = fu.MapPath(os.path.expanduser("~/Desktop"))
        print(f"Stills folder not set. Defaulting to {target_folder} location")
        print(f"Set stills location with set_stills_location script")
    return target_folder


def get_timeline_and_gallery(resolve):
    project = resolve.GetProjectManager().GetCurrentProject()
    timeline = project.GetCurrentTimeline()
    gallery = project.GetGallery()
    return timeline, gallery


def get_export_album(albums: list, album_name: str):
    export_album = None
    for album in albums:
        if gallery.GetAlbumName(album) == album_name:
            gallery.SetCurrentStillAlbum(album)
            export_album = gallery.GetCurrentStillAlbum()
            return export_album
    if not export_album:
        print(
            f"Cannot create the album '{album_name}' for you. Do it manually, please"
        )


def grab_still(album_name: str):
    """
    create still from current position on the timeline
    save the files to the predefined folder
    """
    if not fu.GetResolve():
        print("This is a script for Davinci Resolve")
        return

    albums = gallery.GetGalleryStillAlbums()
    current_clip_name = timeline.GetCurrentVideoItem().GetName()
    timeline_name = timeline.GetName()
    now = datetime.now()
    date_time = now.strftime("%m%d%Y")
    file_prefix = f"{current_clip_name}_{date_time}_{timeline_name}"
    export_album = get_export_album(albums, album_name)
    if not export_album:
        return
    still = timeline.GrabStill(STILL_FRAME_REF)
    export_album.SetLabel(still, current_clip_name)
    export_album.ExportStills([still], target_folder, file_prefix, "png")
    # export_album.DeleteStills(still)
    # resolve.OpenPage("edit")
    print(f"Saved {file_prefix} to {target_folder}")


if __name__ == "__main__":
    timeline, gallery = get_timeline_and_gallery(resolve)
    target_folder = get_target_folder()
    grab_still(album_name=EXPORT_ALBUM)
