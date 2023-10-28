import sys
from pathlib import Path


def get_fusion_module():
    """Get current Fusion instance"""
    fusion = getattr(sys.modules["__main__"], "fusion", None)
    return fusion


def cleanup_drx(folder: Path):
    print(
        "CLEANUP DRX is enabled, all .drx files in the stills location will be erased"
    )
    answer = confirmation_dialogue(
        title="DRX files deletion!",
        request=f"Do you wish to delete all DRX files\nin'{folder.name}'?",
    )
    for file in folder.iterdir():
        if file.suffix == ".drx":
            file.unlink()


def create_folder(folder_path: Path) -> None:
    try:
        Path.mkdir(folder_path, exist_ok=True, parents=True)
    except PermissionError:
        print(f"Could not create target folder in {folder_path}")
        print("Default folder will be reset.")
        app = get_fusion_module()
        app.SetData("ResolveSaveStills.Folder")
        print("Restart the script!")
        raise
    except FileNotFoundError:
        print("Wrong path is specified")
        raise


def get_timeline_and_gallery(resolve):
    project = resolve.GetProjectManager().GetCurrentProject()
    timeline = project.GetCurrentTimeline()
    gallery = project.GetGallery()
    return timeline, gallery


def confirmation_dialogue(title=None, request=None):
    fu = get_fusion_module()
    target = fu.GetData("ResolveSaveStills.Folder")

    ui = fu.UIManager
    disp = bmd.UIDispatcher(ui)
    win = disp.AddWindow(
        {
            "ID": "RequestFolder",
            "TargetID": "RequestFolder",
            "WindowTitle": title or "Confirmation Dialogue",
            "Geometry": [800, 600, 550, 100],
        },
        [
            ui.VGroup(
                [
                    ui.Label(
                        {
                            "ID": "Lbl1",
                            "Text": f"<H1>{title}<H1/>",
                            "Weight": 0.5,
                            "Alignment": {"AlignHCenter": True, "AlignVCenter": True},
                        }
                    ),
                    ui.Label(
                        {
                            "ID": "Lbl2",
                            "Text": request,
                            "Weight": 0.5,
                            "Alignment": {"AlignHCenter": True, "AlignVCenter": True},
                        }
                    ),
                    ui.HGroup(
                        {"Alignment": {"AlignHRight": True}, "Weight": 0},
                        [
                            ui.Button(
                                {
                                    "ID": "OkButton",
                                    "Text": "Ok",
                                }
                            ),
                            ui.Button(
                                {
                                    "ID": "CancelButton",
                                    "Text": "Cancel",
                                }
                            ),
                        ],
                    ),
                ]
            ),
        ],
    )
    itm = win.GetItems()
    answer = False

    def close(ev):
        disp.ExitLoop()

    def request_confirmed(ev):
        nonlocal answer
        print("Ok!")
        answer = True
        disp.ExitLoop()

    win.On.OkButton.Clicked = request_confirmed
    win.On.CancelButton.Clicked = close
    win.On.RequestFolder.Close = close
    win.Show()
    disp.RunLoop()
    win.Hide()
    return answer


def request_dir(window_title: Path):
    """request file UI"""

    fu = get_fusion_module()
    target = fu.GetData("ResolveSaveStills.Folder")

    ui = fu.UIManager
    disp = bmd.UIDispatcher(ui)
    win = disp.AddWindow(
        {
            "ID": "RequestFolder",
            "TargetID": "RequestFolder",
            "WindowTitle": window_title,
            "Geometry": [800, 600, 630, 50],
        },
        ui.HGroup(
            [
                ui.Label({"Weight": 0.1, "ID": "FolderLabel", "Text": "folder:"}),
                ui.LineEdit(
                    {
                        "Weight": 0.8,
                        "Text": target or "",
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
    if result:
        fu.SetData("ResolveSaveStills.Folder", result)
    else:
        print(
            f"Tagret folder location is not saved. You can save folder location data by running Set Stills Location script"
        )
    return result


if __name__ == "__main__":
    request_dir()
