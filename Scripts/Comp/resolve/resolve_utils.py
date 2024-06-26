"""
    Utility script for basic Scripting API operations in Davinci Resolve

    License: MIT
    Copyright © 2024 Alexey Bogomolov
    Email: mail@abogomolov.com
    
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
    fusion = get_fusion_module()
    dialog = ConfirmationDialog(
        fusion,
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


def get_project_manager(resolve):
    return resolve.GetProjectManager()


def get_current_project(resolve):
    project_manager = get_project_manager(resolve)
    project = project_manager.GetCurrentProject()
    return project


def get_current_timeline(resolve):
    project = get_current_project(resolve)
    timeline = project.GetCurrentTimeline()
    return timeline


def get_gallery(resolve):
    project_manager = get_project_manager(resolve)
    project = project_manager.GetCurrentProject()
    gallery = project.GetGallery()
    return gallery


class BaseUI:
    def __init__(self, fusion, window_title, geometry, id="DefaultID"):
        self.fusion = fusion
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
    def __init__(self, fusion, title=None, request=None, info=[]):
        self.title = "Confirmation Dialog" if title is None else title
        self.request = request
        self.info = info
        self.confirmed = False

        # Truncate the info list
        if len(self.info) > 10:
            self.info = self.info[:10]
            print("Confirmation dialogue is truncated to first 10 elements")
        # Convert info to HTML content
        self.info_html = self.info_to_html(self.info)
        # Adjust the height based on the number of info
        info_height_per_line = 20  # Estimated height per line

        additional_height = len(self.info) * info_height_per_line
        base_width, base_height, win_x, win_y = 800, 600, 450, 130
        adjusted_height = win_y + additional_height  # Add some padding for aesthetics

        geometry = [base_width, base_height, win_x, adjusted_height]
        super().__init__(fusion, self.title, geometry, id="ConfirmationDialog")
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

    def info_to_html(self, info: list):
        max_length = 80  # Maximum allowed length for a line
        html_content = ""
        for line in info:
            if len(line) > max_length:
                # Notify developer if the text is too large
                print(
                    f"Warning: Subtitle length exceeds the maximum allowed ({max_length} characters): {line}"
                )
            html_content += f"<p>{line}</p>"
        return html_content

    def layout(self):
        return [
            self.ui.VGroup(
                [
                    self.ui.Label(
                        {
                            "ID": "TitleLabel",
                            "Text": f"<H2>{self.title}</H2>{self.info_html}",
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


class WarningDialog(BaseUI):

    def __init__(self, fusion, message):
        geometry = [800, 700, 400, 80]
        window_title = "Warning message"
        self.message = message
        super().__init__(fusion, window_title, geometry, id="WarningDialog")
        self.itm = self.win.GetItems()
        self.setup_callbacks()

    def setup_callbacks(self):
        self.win.On.OkButton.Clicked = self.close

    def layout(self):
        return [
            self.ui.VGroup(
                [
                    self.ui.Label(
                        {
                            "ID": "TitleLabel",
                            "Text": f"<H2>{self.message}</H2>",
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
                        ],
                    ),
                ]
            )
        ]

    def run(self):
        self.show()


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
                self.ui.Button({"Weight": 0.1, "ID": "SaveButton", "Text": "Select"}),
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
