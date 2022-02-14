#!/usr/bin/env python

"""
    This is a Davinci Resolve script to set stills saving location
    for grab_still and create_stills_from_timeline scripts.
    Author: Alexey Bogomolov
    Email: mail@abogomolov.com
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
                ui.Button({"Weight": 0.1, "ID": "RunButton", "Text": "Ok"}),
            ]
        ),
    )
    itm = win.GetItems()

    def close(ev):
        disp.ExitLoop()

    def request_folder(ev):
        folder = fu.RequestDir()
        itm["FolderLine"].Text = folder

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


if __name__ == "__main__":
    target_folder = request_dir()
    if not target_folder or target_folder == " ":
        print("Stills folder not set. Defaulting to Desktop location")
    else:
        print(f"Stills export directory is set to {target_folder}")
