#!/usr/bin/env python

"""
    This is a Davinci Resolve script to save all timeline clips as jpg files.
    Author: Alexey Bogomolov
    Email: mail@abogomolov.com
    License: MIT
    Copyright: 2022
"""

STILL_FRAME_REF = 2


def request_dir():
    """request file UI"""
    target = fu.GetData("ResolveSaveStills.Folder")

    ui = fu.UIManager
    disp = bmd.UIDispatcher(ui)
    win = disp.AddWindow(
        {
            "ID": "RequestFolder",
            "TargetID": "RequestFolder",
            "WindowTitle": "The stills will be saved to",
            "Geometry": [800, 600, 630, 50],
        },
        ui.HGroup(
            [
                ui.Label({"Weight": 0.1, "ID": "FolderLabel", "Text": "folder:"}),
                ui.LineEdit(
                    {
                        "Weight": 0.8,
                        "Text": target or " ",
                        "ID": "FolderLine",
                        "Events": {"ReturnPressed": True},
                        "Alignment": {"AlignHCenter": True, "AlignVCenter": True},
                    }
                ),
                ui.Button({"Weight": 0.2, "ID": "FolderButton", "Text": "Browse..."}),
                ui.Button({"Weight": 0.1, "ID": "RunButton", "Text": "Run"}),
            ]
        ),
    )
    itm = win.GetItems()

    def close(ev):
        disp.ExitLoop()

    def request_folder(ev):
        target_folder = fu.RequestDir()
        itm["FolderLine"].Text = target_folder

    itm["FolderLine"].SetPlaceholderText("Select folder")
    win.On.FolderButton.Clicked = request_folder
    win.On.RequestFolder.Close = close
    win.On.RunButton.Clicked = close
    win.Show()
    disp.RunLoop()
    win.Hide()
    result = itm["FolderLine"].Text
    fu.SetData("ResolveSaveStills.Folder", result)
    return result


def grab_stills():
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
    stills = timeline.GrabAllStills(STILL_FRAME_REF)
    album = gallery.GetCurrentStillAlbum()

    if len(stills) == 0:
        print("no stills saved")
        return
    folder = request_dir()
    if folder:
        print(f"saving stills to {folder}")
    else:
        print("Stills folder not set. Defaulting to desktop location")
        target_folder = fu.MapPath(os.path.expanduser("~/Desktop"))
        print(f"saving stills to {target_folder}")
    album.ExportStills(stills, folder, timeline_name, "jpg")
    album = gallery.GetCurrentStillAlbum()
    album.DeleteStills(stills)
    resolve.OpenPage("edit")


grab_stills()
