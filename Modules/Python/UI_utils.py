"""
    Utility script for basic Scripting API UI operations in Davinci Resolve and Fusion

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


class BaseUI:
    def __init__(self, window_title, geometry=[800, 600, 440, 130], id="DefaultID"):
        self.fusion = get_fusion_module()
        self.ui = self.fusion.UIManager
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


class ConfirmationDialogMeta(type):
    def __call__(cls, *args, **kwargs):
        # Create the instance
        instance = super().__call__(*args, **kwargs)
        # Automatically run the dialog and return the result
        return instance.run()


class ConfirmationDialog(BaseUI, metaclass=ConfirmationDialogMeta):
    def __init__(self, title=None, request=None, info=[]):
        self.title = "Confirmation Dialog" if title is None else title
        self.request = request
        self.info = info
        self.confirmed = False
        self.win_x = 500
        self.win_y = 130

        # Truncate the info list if too long, and notify
        max_info_items = 5
        if len(self.info) > max_info_items:
            self.info = self.info[:max_info_items]
            print(f"Confirmation dialog is truncated to the first {max_info_items} elements.")

        # Convert info to HTML content, with line truncation and visual indicators for long lines
        self.info_html = self.info_to_html(self.info)

        # Adjust dialog height dynamically based on info length
        info_height_per_line = 22  # Estimated height per line
        additional_win_height = len(self.info) * info_height_per_line
        screen_x, screen_y = 800, 600
        adjusted_win_height = self.win_y + additional_win_height

        geometry = [screen_x, screen_y, self.win_x, adjusted_win_height]
        super().__init__(self.title, geometry, id="ConfirmationDialog")
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
        max_visible_length = self.win_x // 6  # Approximate characters fitting in window x (assuming ~8px/char)
        truncated_suffix = "..."  # Suffix to indicate truncated text
        html_content = ""

        for line in info:
            if len(line) > max_visible_length:
                print(f"Warning: Line exceeds maximum width. Truncating: {line}")
                # Truncate the line for display, show only part of it with an ellipsis
                truncated_line = line[:max_visible_length - len(truncated_suffix)] + truncated_suffix
                html_content += f"<p style='word-wrap: break-word;'>{truncated_line}</p>"
            else:
                html_content += f"<p style='word-wrap: break-word;'>{line}</p>"

        return html_content

    def layout(self):
        return [
            self.ui.VGroup(
                [
                    self.ui.Label(
                        {
                            "ID": "TitleLabel",
                            "Text": f"<H3>{self.title}</H3>{self.info_html}",
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

    def __init__(self, message):
        geometry = [800, 700, 400, 80]
        window_title = "Warning message"
        self.message = message
        super().__init__(window_title, geometry, id="WarningDialog")
        self.itm = self.win.GetItems()
        self.setup_callbacks()
        self.show()

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


class RequestDialogMeta(type):
    def __call__(cls, *args, **kwargs):
        # Create the instance of the class and automatically run the dialog
        instance = super().__call__(*args, **kwargs)
        return instance.run()


class BaseRequestDialog(BaseUI, metaclass=RequestDialogMeta):

    def __init__(self, title=None, target=None, request_type=None):
        self.title = "Choose Directory" if title is None else title
        geometry = [800, 700, 630, 50]
        self.target = target or Path("~/Desktop").expanduser().absolute()
        self.request_type = request_type  # Specify if it's a dir or file request
        super().__init__(self.title, geometry, id="RequestDialog")
        self.itm = self.win.GetItems()
        self.setup_callbacks()

    def setup_callbacks(self):
        self.win.On.RequestButton.Clicked = self.request_action_callback
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

    def request_action_callback(self, ev):
        # Dynamically call self.fusion.RequestDir or self.fusion.RequestFile
        if self.request_type == "dir":
            target = self.fusion.RequestDir(self.target)
        elif self.request_type == "file":
            target = self.fusion.RequestFile(self.target)

        if target:
            self.itm["FolderLine"].Text = target

    def run(self):
        self.show()
        return self.itm["FolderLine"].Text

    @classmethod
    def get_selected(cls, title=None, target=None, request_action=None):
        """deprecated"""
        instance = cls(title, target, request_action)
        return instance.run()


class RequestDir(BaseRequestDialog):
    def __init__(self, title=None, target=None):
        super().__init__(title, target, request_type="dir")  # Specify directory request


class RequestFile(BaseRequestDialog):
    def __init__(self, title=None, target=None):
        super().__init__(title, target, request_type="file")  # Specify file request

