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

from pathlib import Path
from log_utils import set_logging

log = set_logging()


def get_fusion_module(app_name="Fusion"):
    """Get current Fusion instance"""
    bmd = None
    fusion = None
    try:
        from bmd_utils import get_bmd_object, get_app
        bmd = get_bmd_object(app_name)
        fusion = get_app(app_name)
    except ModuleNotFoundError:
        print(f"Fusion module not found for the app {app_name}")
    return bmd, fusion


class BaseUI:
    def __init__(self, window_title, geometry=[800, 600, 400, 200], id="DefaultID", 
                 resizable=True, min_size=None, max_size=None, modal=False):
        self.bmd, self.fusion = get_fusion_module()
        self.ui = self.fusion.UIManager
        self.id = id
        self.disp = self.bmd.UIDispatcher(self.ui)
        self.window_title = window_title
        self.geometry = geometry
        self.resizable = resizable
        self.min_size = min_size
        self.max_size = max_size
        self.modal = modal
        self.itm = None
        self.win = self.create_window(self.geometry)
        self.setup_close_event()

    def setup_close_event(self):
        self.win.On[self.id].Close = self.close

    def create_window(self, geometry):
        # Use standard window decorations to ensure the title bar/system menu are visible
        window_flags = {
            "Window": True,
            "WindowTitleHint": True,
            "WindowSystemMenuHint": True,
            "WindowCloseButtonHint": True,
            "WindowStaysOnTopHint": True,
        }

        window_props = {
            "ID": self.id,
            "TargetID": self.id,
            "WindowTitle": self.window_title,
            "WindowFlags": window_flags,
            "Geometry": geometry,
            "Resize": self.resizable,
        }
        
        # Add modal behavior if requested
        if self.modal:
            window_props["WindowModality"] = "ApplicationModal"
        
        # Add size constraints if specified
        if self.min_size:
            window_props["MinimumSize"] = self.min_size
        if self.max_size:
            window_props["MaximumSize"] = self.max_size

        self.win = self.disp.AddWindow(window_props, self.layout())
        
        # Force resize if geometry is significantly different from default
        if self.resizable and geometry != [800, 600, 400, 200]:
            try:
                self.win.Resize(geometry[2], geometry[3])  # width, height
            except Exception:
                pass
                
        return self.win

    def layout(self, *args):
        log.debug("Layout not implemented in the subclass. Using Empty Layout")
        return self.ui.VGroup([])

    def show(self):
        self.win.Show()
        self.disp.RunLoop()
        self.win.Hide()

    def close(self, ev=None):
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
        self.request = request or "Do you want to proceed?"
        self.info = info
        self.confirmed = False
        self.win_x = 500
        self.win_y = 130

        # Truncate the info list if too long, and notify
        max_info_items = 5
        if len(self.info) > max_info_items:
            self.info = self.info[:max_info_items]
            log.debug(
                f"Confirmation dialog is truncated to the first {max_info_items} elements."
            )

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
        max_visible_length = (
            self.win_x // 6
        )  # Approximate characters fitting in window x (assuming ~6px/char)
        truncated_suffix = "..."  # Suffix to indicate truncated text
        html_content = ""

        for line in info:
            if len(line) > max_visible_length:
                log.debug(f"Warning: Line exceeds maximum width. Truncating: {line}")
                # Truncate the line for display, show only part of it with an ellipsis
                truncated_line = (
                    line[: max_visible_length - len(truncated_suffix)]
                    + truncated_suffix
                )
                html_content += (
                    f"<p style='word-wrap: break-word;'>{truncated_line}</p>"
                )
            else:
                html_content += f"<p style='word-wrap: break-word;'>{line}</p>"

        return html_content

    def layout(self):
        return self.ui.VGroup(
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
        )


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
        return self.ui.VGroup(
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


class RequestDialogMeta(type):
    def __call__(cls, *args, **kwargs):
        # Create the instance of the class and automatically run the dialog
        instance = super().__call__(*args, **kwargs)
        return instance.run()


class BaseRequestDialog(BaseUI, metaclass=RequestDialogMeta):

    def __init__(self, title=None, target=None, request_type=None, file_mask=None):
        self.title = "Choose Output" if title is None else title
        self.result = None
        geometry = [800, 700, 660, 50]
        self.target = target or Path("~/Desktop").expanduser().absolute()
        if isinstance(file_mask, dict):
            self.file_mask = file_mask
        self.request_type = request_type  # Specify if it's a dir or file request
        super().__init__(self.title, geometry, id="RequestDialog")
        self.itm = self.win.GetItems()
        self.setup_callbacks()

    def setup_callbacks(self):
        self.win.On.RequestButton.Clicked = self.request_action_callback
        self.win.On.RequestDialog.Close = self.cancel
        self.win.On.SetPathButton.Clicked = self.set_path

    def layout(self):
        return self.ui.HGroup(
            [
                self.ui.Label({"Weight": 0.1, "ID": "FolderLabel", "Text": "folder:"}),
                self.ui.LineEdit(
                    {
                        "Weight": 0.8,
                        "Text": str(self.target),
                        "ID": "PathTextLine",
                        "Events": {"ReturnPressed": True},
                        "Alignment": {"AlignHCenter": True, "AlignVCenter": True},
                    }
                ),
                self.ui.Button(
                    {"Weight": 0.2, "ID": "RequestButton", "Text": "Browse..."}
                ),
                self.ui.Button({"Weight": 0.1, "ID": "SetPathButton", "Text": "Set"}),
            ]
        )

    def request_action_callback(self, ev):
        # Dynamically call self.fusion.RequestDir or self.fusion.RequestFile
        if self.request_type == "dir":
            out_path = self.fusion.RequestDir(self.target)
        elif self.request_type == "file":
            out_path = self.fusion.RequestFile(self.target, "", self.file_mask)

        log.debug(f"Request type: {self.request_type}")
        if out_path:
            self.itm["PathTextLine"].Text = out_path
        else:
            message = "Folder not chosen" if self.request_type == "dir" else "File not chosen"
            WarningDialog(message)
            # Instead of closing, show the dialog again
            return

    def run(self):
        self.show()
        return self.result

    def set_path(self, ev):
        self.result = self.itm["PathTextLine"].Text
        self.close()

    def cancel(self, ev=None):
        self.result = None
        self.close()


class RequestDir(BaseRequestDialog):
    def __init__(self, title=None, target=None):
        super().__init__(title, target, request_type="dir")  # Specify directory request


class RequestFile(BaseRequestDialog):
    def __init__(self, title=None, target=None, file_mask=None):
        super().__init__(title, target, request_type="file", file_mask=file_mask)  # Specify file request
