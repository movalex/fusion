"""
    Add current comp and loader paths to the clipboard

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

from fusion_utils import BaseUI
from pathlib import Path

comp = fu.GetCurrentComp()


class ShowUI(BaseUI):
    def __init__(self, fusion, title=None):
        self.title = "Main Window" if title is None else title
        geometry = [800, 600, 440, 130]
        super().__init__(fusion, self.title, geometry, id="VFXSetup")
        self.setup_callbacks()
        self.itm = self.win.GetItems()

    def setup_callbacks(self):
        self.win.On.CopyCompPath.Clicked = self.copy_comp_path
        self.win.On.CopyLoaderPath.Clicked = self.copy_loader_path
        self.win.On.CopyNukePath.Clicked = self.copy_nuke_path
        self.win.On.CancelButton.Clicked = self.close
        self.win.On.VFXSetup.Close = self.close

    def get_comp_attributes(self):
        return comp.GetAttrs()

    def get_loader_clip(self):
        loaders = comp.GetToolList(False, "Loader")
        loader_clips = []
        for loader in loaders.values():
            file_path = Path(loader.Clip[0]).as_posix()
            loader_clips.append(file_path)

        return loader_clips

    def copy_comp_path(self, ev):
        comp_attrs = self.get_comp_attributes()
        output = Path(comp_attrs["COMPS_FileName"])
        print(f"{output.as_posix()}\n")
        comp.Execute(f"bmd.setclipboard('{output.as_posix()}')")

    def copy_loader_path(self, ev):
        clips = self.get_loader_clip()
        output = ("\n").join(clips)
        print(f"{output}\n")
        comp.Execute(f"bmd.setclipboard('{output}')")

    def copy_nuke_path(self, ev):
        saver = comp.GetToolList(False, "Saver")[1]
        clip = saver.Clip[1]
        clip = Path(clip.replace("00000000", r"%08d")).as_posix()
        print(f"{clip}\n")
        comp.Execute(f"bmd.setclipboard('{clip}')")

    def layout(self):
        ui = self.ui

        return [
            ui.VGroup(
                [
                    ui.HGroup(
                        [
                            ui.Label(
                                {
                                    "ID": "TimelinesLabel",
                                    "Text": "Current Comp:",
                                    "AlignmentFlag": "AlignCenter",
                                }
                            ),
                            ui.Label(
                                {
                                    "ID": "CompNameLabel",
                                    "Text": comp.GetAttrs()["COMPS_Name"],
                                    "AlignmentFlag": "AlignRight",
                                }
                            ),
                        ],
                    ),
                    ui.HGroup(
                        [
                            ui.Button({"ID": "CopyCompPath", "Text": "Copy Comp Path"}),
                            ui.Button(
                                {"ID": "CopyLoaderPath", "Text": "Copy Loader Path"}
                            ),
                            ui.Button({"ID": "CopyNukePath", "Text": "Copy Nuke Path"}),
                        ]
                    ),
                    ui.HGroup(
                        [
                            ui.Button({"ID": "CancelButton", "Text": "Cancel"}),
                        ],
                    ),
                ],
            ),
        ]


ShowUI(fu, "VFX Setup").show()
