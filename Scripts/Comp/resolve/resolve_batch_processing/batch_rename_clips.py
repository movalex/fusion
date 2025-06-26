#!/usr/bin/env python

"""
    This is a Davinci Resolve script to batch rename clips (WIP)
    Author: Alexey Bogomolov
    Email: mail@abogomolov.com
    License: MIT
    Copyright: 2023
"""
from bmd_utils import get_bmd_object, get_resolve_fusion

bmd = get_bmd_object("Resolve")
resolve = bmd.scriptapp("Resolve")
fu = get_resolve_fusion()


def request_track_number():
    """request file UI"""
    value = fu.GetData("RenameClips.TrackNumber")

    ui = fu.UIManager
    disp = bmd.UIDispatcher(ui)
    win = disp.AddWindow(
        {
            "ID": "RequestTrack",
            "TargetID": "RequestTrack",
            "WindowTitle": "Select track number",
            "Geometry": [800, 600, 230, 100],
        },
        [
            ui.VGroup(
                [
                    ui.HGroup(
                        [
                            ui.Label(
                                {"Weight": 0.6, "ID": "Label", "Text": "Track Num:"}
                            ),
                            ui.SpinBox(
                                {
                                    "Weight": 0.4,
                                    "ID": "SpinBox",
                                    "Value": int(value) or 0,
                                    "Minimum": 1,
                                    "Alignment": {
                                        "AlignHCenter": True,
                                        "AlignVCenter": True,
                                    },
                                }
                            ),
                        ]
                    ),
                    ui.HGroup(
                        [
                            ui.Button({"Weight": 0.2, "ID": "OkButton", "Text": "Ok"}),
                            ui.Button(
                                {"Weight": 0.2, "ID": "CancelButton", "Text": "Cancel"}
                            ),
                        ]
                    ),
                ],
            )
        ],
    )
    itm = win.GetItems()

    def close(ev):
        disp.ExitLoop()

    def process(ev):
        track_number = itm["SpinBox"].Value
        print(track_number)
        print(ev)
        rename_clips(int(track_number))

    def save_data(ev):
        track_number = itm["SpinBox"].Value
        fu.SetData("RenameClips.TrackNumber", track_number)

    win.On.SpinBox.ValueChanged = save_data
    track_number = itm["SpinBox"].Value
    win.On.OkButton.Clicked = process
    win.On.CancelButton.Clicked = close
    win.On.RequestTrack.Close = close
    win.Show()
    disp.RunLoop()
    win.Hide()


def get_markers(clip):
    for marker_data in clip.GetMarkers().values():
        name = marker_data["name"]
        print("Marker name: ", name)


def rename_clips(track_number: int):
    """batch rename clips

    currently WIP, does not do anything...
    UPD: Welp, looks like it is not currently possible to change individual clips names with scripting

    """

    if not fu.GetResolve():
        print("This is a script for Davinci Resolve")
        return
    project = resolve.GetProjectManager().GetCurrentProject()
    timeline = project.GetCurrentTimeline()
    clips = timeline.GetItemListInTrack("Video", int(track_number))
    if not clips:
        print(f"No clips on the track #{track_number}")
        return
    print(f"Processing track #{track_number}")

    for clip in clips:
        print(f"Getting clip name: {clip.GetName()}")

    print(dir(clip))
    print("PROP", clip.GetProperty())


if __name__ == "__main__":
    request_track_number()
