#!/usr/bin/env python

"""
    This is a Davinci Resolve script to save all timeline clips as jpg files.
    Author: Alexey Bogomolov
    Email: mail@abogomolov.com
    License: MIT
    Copyright: 2022
"""

from os import rename


STILL_FRAME_REF = 2


def request_track_number():
    """request file UI"""
    target = fu.GetData("RenameClips.TrackNumber")

    ui = fu.UIManager
    disp = bmd.UIDispatcher(ui)
    win = disp.AddWindow(
        {
            "ID": "RenameClipsWindow",
            "TargetID": "RenameClipsWindow",
            "WindowTitle": "The stills will be saved to",
            "Geometry": [800, 600, 230, 50],
        },
        ui.HGroup(
            [
                ui.Label({"Weight": 0.1, "ID": "FolderLabel", "Text": "folder:"}),
                ui.LineEdit(
                    {
                        "Weight": 0.8,
                        "Text": target or " ",
                        "ID": "TextLine",
                        "Events": {"ReturnPressed": True},
                        "Alignment": {"AlignHCenter": True, "AlignVCenter": True},
                    }
                ),
                ui.Button({"Weight": 0.2, "ID": "OkButton", "Text": "Ok"}),
                # ui.Button({"Weight": 0.1, "ID": "CancelButton", "Text": "Cancel"}),
            ]
        ),
    )
    itm = win.GetItems()

    def close(ev):
        disp.ExitLoop()

    # def request_folder(ev):
    #     target_folder = fu.RequestDir()
    #     itm["TextLine"].Text = target_folder

    itm["TextLine"].SetPlaceholderText("Select folder")
    win.On.OkButton.Clicked = close
    win.On.RenameClipsWindow.Close = close
    # win.On.CancelButton.Clicked = close
    win.Show()
    disp.RunLoop()
    win.Hide()
    result = itm["TextLine"].Text
    fu.SetData("RenameClips.TrackNumber", result)
    return result


def rename_clips(track_number):
    """batch rename clips"""

    if not fu.GetResolve():
        print("This is a script for Davinci Resolve")
        return
    project = resolve.GetProjectManager().GetCurrentProject()
    timeline = project.GetCurrentTimeline()
    clips = timeline.GetItemListInTrack("Video", int(track_number))
    if len(clips) == 0:
        print(f"no clips on the track #{track_number}")
        return

    for clip in clips:
        print(f"changing name of {clip.GetName()}")
        print(clip.GetMarkers())

    print(dir(clip))


track = request_track_number()
rename_clips(track)