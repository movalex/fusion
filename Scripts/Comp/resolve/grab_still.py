#!/usr/bin/env python

import os

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


def get_target_folder():
    target_folder = fu.GetData("ResolveSaveStills.Folder")
    if not target_folder or target_folder == " ":
        target_folder = fu.MapPath(os.path.expanduser("~/Desktop"))
        print(f"Stills folder not set. Defaulting to {target_folder} location")
        print(f"Set stills location with set_stills_location script")
    return target_folder


def get_timeline_and_gallery():
    project = resolve.GetProjectManager().GetCurrentProject()
    timeline = project.GetCurrentTimeline()
    gallery = project.GetGallery()
    return timeline, gallery


def grab_still():
    """
    create still from current position on the timeline
    save the files to the predefined folder
    location is not defined by set_stills_location script, still is saved to Desktop
    delete the still from the gallery afterwards
    """
    if not fu.GetResolve():
        print("This is a script for Davinci Resolve")
        return

    timeline, gallery = get_timeline_and_gallery()
    albums = gallery.GetGalleryStillAlbums()
    album_names = [gallery.GetAlbumName(album) for album in albums]
    if not "export" in album_names:
        print("Create export album!")
        return
    current_clip_name = timeline.GetCurrentVideoItem().GetName()
    timeline_name = timeline.GetName()
    file_prefix = f"{current_clip_name}_{timeline_name}"
    target_folder = get_target_folder()
    for album in albums:
        if gallery.GetAlbumName(album) == "export":
            gallery.SetCurrentStillAlbum(album)
            current_album = gallery.GetCurrentStillAlbum()
            still = timeline.GrabStill(STILL_FRAME_REF)
            current_album.SetLabel(still, current_clip_name)
            current_album.ExportStills([still], target_folder, file_prefix, "png")
            # current_album.DeleteStills(still)
            resolve.OpenPage("edit")
            print(f"Saved {file_prefix} to {target_folder}")


if __name__ == "__main__":
    grab_still()
