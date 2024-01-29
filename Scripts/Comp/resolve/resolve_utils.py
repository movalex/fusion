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
    dialog = ConfirmationDialog(
        fu,
        title="DRX files deletion!",
        request=f"Do you wish to delete all DRX files\nin'{folder}' folder?",
    )
    answer = dialog.run()

    if answer:
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


class ConfirmationDialog:
    def __init__(self, fusion, title=None, request=None):
        self.confirmed = False
        self.title = "Confirmation Dialog" if title is None else title
        self.request = request
        self.confirmed = False

        self.ui = fusion.UIManager
        self.disp = bmd.UIDispatcher(self.ui)
        self.win = self.create_window()
        self.setup_callbacks()

    def setup_callbacks(self):
        self.win.On.OkButton.Clicked = self.request_confirmed
        self.win.On.CancelButton.Clicked = self.close
        self.win.On.RequestFolder.Close = self.close

    def run(self):
        self.win.Show()
        self.disp.RunLoop()
        self.win.Hide()
        return self.confirmed

    def close(self, ev):
        self.disp.ExitLoop()

    def request_confirmed(self, ev):
        self.confirmed = True
        self.disp.ExitLoop()

    def create_window(self):
        return self.disp.AddWindow(
            {
                "ID": "RequestFolder",
                "TargetID": "RequestFolder",
                "WindowTitle": "Confirmation Dialogue",
                "Geometry": [800, 600, 550, 130],
            },
            [
                self.ui.VGroup(
                    [
                        self.ui.Label(
                            {
                                "ID": "TitleLabel",
                                "Text": f"<H2>{self.title}<H2/>",
                                "Weight": 0.5,
                                "Alignment": {
                                    "AlignHCenter": True,
                                    "AlignVCenter": True,
                                },
                            }
                        ),
                        self.ui.Label(
                            {
                                "ID": "RequestLabel",
                                "Text": self.request,
                                "Weight": 0.5,
                                "Alignment": {
                                    "AlignHCenter": True,
                                    "AlignVCenter": True,
                                },
                            }
                        ),
                        self.ui.HGroup(
                            {"Alignment": {"AlignHRight": True}, "Weight": 0},
                            [
                                self.ui.Button(
                                    {
                                        "ID": "OkButton",
                                        "Text": "Ok",
                                    }
                                ),
                                self.ui.Button(
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


def request_dir(window_title: str, target=None):
    """request file UI"""

    fu = get_fusion_module()
    if target is None:
        target = Path("~/Desktop").expanduser().absolute()

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
                        "Text": str(target) or "",
                        "ID": "FolderLine",
                        "Events": {"ReturnPressed": True},
                        "Alignment": {"AlignHCenter": True, "AlignVCenter": True},
                    }
                ),
                ui.Button({"Weight": 0.2, "ID": "FolderButton", "Text": "Browse..."}),
                ui.Button({"Weight": 0.1, "ID": "RunButton", "Text": "Save"}),
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
    print(f"result: '{result}'")

    return result


if __name__ == "__main__":
    request_dir()
