#!/usr/bin/env python

import os
import time

"""
    This is a Davinci Resolve script to save single still in stills folder
    Author: Alexey Bogomolov
    Email: mail@abogomolov.com
    License: MIT
    Copyright: 2022
"""
STILL_FRAME_REF = 2


def grab_still():
    """create stills from all clips in a timeline
    save the files to requested folder
    """
    if not fu.GetResolve():
        print("This is a script for Davinci Resolve")
        return

    project = resolve.GetProjectManager().GetCurrentProject()
    timeline = project.GetCurrentTimeline()
    timeline_name = timeline.GetName()
    gallery = project.GetGallery()
    still = timeline.GrabStill(STILL_FRAME_REF)
    album = gallery.GetCurrentStillAlbum()
    target_folder = fu.GetData("ResolveSaveStills.Folder")

    if not target_folder or target_folder == " ":
        target_folder = fu.MapPath(os.path.expanduser("~/Desktop"))
        print(f"Stills folder not set. Defaulting to {target_folder} location")
        print(f"You can set stills location with set_stills_location script (obviously)")
    
    album.ExportStills([still], target_folder, timeline_name, "jpg")
    # album.DeleteStills(still)
    resolve.OpenPage("edit")
    print(f"Saved still to {target_folder}")


if __name__ == "__main__":
    grab_still()
