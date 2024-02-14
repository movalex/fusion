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


class BaseUI:
    def __init__(self, fusion, window_title, geometry, id="DefaultID"):
        self.fusion = fusion
        print(fusion)
        self.ui = fusion.UIManager
        self.id = id
        self.disp = bmd.UIDispatcher(self.ui)
        self.window_title = window_title
        self.geometry = geometry
        self.itm = None
        self.win = self.create_window(self.geometry)

    def create_window(self, geometry):
        self.win = self.disp.AddWindow(
            {
                "ID": self.id,
                "TargetID": self.id,
                "WindowTitle": self.window_title,
                "Geometry": geometry,
            },
            self.layout(),  # This method should be implemented in subclasses to define the layout
        )
        return self.win

    def layout(self, *args):
        # Placeholder for layout, should be overridden in subclasses
        raise NotImplementedError

    def show(self):
        self.win.Show()
        self.disp.RunLoop()
        self.win.Hide()

    def close(self, ev):
        self.disp.ExitLoop()


class ConfirmationDialog(BaseUI):
    def __init__(self, fusion, title=None, request=None):
        self.title = "Confirmation Dialog" if title is None else title
        self.request = request
        geometry = [800, 600, 550, 130]
        super().__init__(fusion, self.title, geometry, id="ConfirmationDialog")
        self.confirmed = False
        self.setup_callbacks()

    def setup_callbacks(self):
        self.win.On.OkButton.Clicked = self.request_confirmed
        self.win.On.CancelButton.Clicked = self.close
        self.win.On.RequestFolder.Close = self.close

    def run(self):
        self.show()
        return self.confirmed

    def request_confirmed(self, ev):
        self.confirmed = True
        self.disp.ExitLoop()

    def layout(self):
        return [
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
        ]


class BaseRequestDialog(BaseUI):
    def __init__(self, fusion, title=None, target=None):
        self.title = "Choose Directory" if title is None else title
        geometry = [800, 700, 630, 50]
        self.target = target or Path("~/Desktop").expanduser().absolute()
        super().__init__(fusion, self.title, geometry, id="RequestDialog")
        self.itm = self.win.GetItems()
        self.setup_callbacks()

    def setup_callbacks(self):
        self.win.On.RequestButton.Clicked = self.request_action
        self.win.On.RequestDialog.Close = self.close
        self.win.On.SaveButton.Clicked = self.close

    def layout(self):
        return self.ui.HGroup(
            [
                self.ui.Label({"Weight": 0.1, "ID": "FolderLabel", "Text": "folder:"}),
                self.ui.LineEdit(
                    {
                        "Weight": 0.8,
                        "Text": str(self.target),
                        "ID": "FolderLine",
                        "Events": {"ReturnPressed": True},
                        "Alignment": {"AlignHCenter": True, "AlignVCenter": True},
                    }
                ),
                self.ui.Button(
                    {"Weight": 0.2, "ID": "RequestButton", "Text": "Browse..."}
                ),
                self.ui.Button({"Weight": 0.1, "ID": "SaveButton", "Text": "Save"}),
            ]
        )

    def request_action(self, ev):
        target = self.get_request_action()
        self.itm["FolderLine"].Text = target

    def run(self):
        self.show()
        return self.itm["FolderLine"].Text


class RequestDir(BaseRequestDialog):
    def __init__(self, fusion, title=None, target=None):
        super().__init__(fusion, title, target)

    def get_request_action(self):
        return self.fusion.RequestDir()


class RequestFile(BaseRequestDialog):
    def __init__(self, fusion, title=None, target=None):
        super().__init__(fusion, title, target)

    def get_request_action(self):
        return self.fusion.RequestFile()


if __name__ == "__main__":
    fusion = get_fusion_module()
    RequestDir(fusion).run()
