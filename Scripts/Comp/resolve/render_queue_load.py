"""
    This is a Davinci Resolve script to load render queues

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

import json
import DaVinciResolveScript as dvr_script
from pathlib import Path
from resolve_utils import BaseUI, ConfirmationDialog


resolve = dvr_script.scriptapp("Resolve")
projectManager = resolve.GetProjectManager()
project = projectManager.GetCurrentProject()


def get_render_list():
    queue_file = app.GetData("RenderQueueFilePath")
    if not Path(queue_file).exists():
        print("Export the queue file!")
        return
    with open(queue_file, "r", encoding="utf-8") as file:
        return json.load(file)


def get_timelines():
    current_timelines = {}
    timeline_count = project.GetTimelineCount()
    for i in range(1, timeline_count + 1):
        timeline = project.GetTimelineByIndex(float(i))
        current_timelines[timeline.GetName()] = float(i)
    return current_timelines


def build_queue(preset_name, timeline_name, timeline_name_override, job_list):
    if not job_list:
        print(f"Queue file not found!")
        return
    render_settings = {}
    timeline = project.GetCurrentTimeline()

    current_timelines = get_timelines()

    for n, job in enumerate(job_list):
        if not timeline_name_override:
            timeline_name = job["TimelineName"]
        timeline_idx = current_timelines.get(timeline_name)
        if not timeline_idx:
            print(f"Timeline name {timeline_name} not found in the jobs list")
            continue
        timeline = project.GetTimelineByIndex(timeline_idx)
        project.SetCurrentTimeline(timeline)
        width = job["FormatWidth"]
        file_name = job.get("OutputFilename", f"DefaultOutputFileName_{n:03}")
        file_stem = Path(file_name).stem
        render_job = project.AddRenderJob()
        print(f"Setting preset: {preset_name} for {file_stem}")
        project.LoadRenderPreset(preset_name)
        render_settings["MarkIn"] = job["MarkIn"]
        render_settings["MarkOut"] = job["MarkOut"]
        render_settings["CustomName"] = file_stem
        project.SetRenderSettings(render_settings)


class LoadQueueUI(BaseUI):
    def __init__(self, fusion, timeline_name, title=None):
        self.title = "Main Window" if title is None else title
        geometry = [800, 600, 450, 180]
        self.queue_path = fusion.GetData("RenderQueueFilePath")
        super().__init__(fusion, title, geometry, id="LoadQueueWindow")
        self.timeline_name = timeline_name
        self.itm = self.win.GetItems()
        self.fill_timelines()
        self.fill_custom_presets()
        self.setup_callbacks()

    def setup_callbacks(self):
        self.win.On.CheckBox.Clicked = self.toggle_timelines
        self.win.On.RunButton.Clicked = self.process_queue
        self.win.On.LoadButton.Clicked = self.load_queue_file
        self.win.On.CancelButton.Clicked = self.close
        self.win.On.LoadQueueWindow.Close = self.close

    def fill_timelines(self):
        timelines = get_timelines()
        for tl in timelines.keys():
            self.itm["TimelinesCombo"].AddItem(tl)

    def fill_custom_presets(self):
        preset_list = project.GetRenderPresetList()
        cut_element = "Pro Tools"
        if cut_element in preset_list:
            index = preset_list.index(cut_element) + 1
            preset_list = preset_list[index:]

        for preset in preset_list:
            self.itm["PresetsCombo"].AddItem(preset)

    def layout(self):
        ui = self.ui

        return [
            ui.VGroup(
                [
                    ui.HGroup(
                        {"Weight": 0},
                        [
                            ui.Label(
                                {
                                    "ID": "TimelinesLabel",
                                    "Text": "Choose Timeline:",
                                    "AlignmentFlag": "AlignCenter",
                                }
                            ),
                            ui.Label(
                                {
                                    "ID": "PresetsLabel",
                                    "Text": "Choose Preset:",
                                    "AlignmentFlag": "AlignCenter",
                                }
                            ),
                        ],
                    ),
                    ui.HGroup(
                        {"Weight": 0},
                        [
                            ui.ComboBox(
                                {
                                    "ID": "TimelinesCombo",
                                    "Text": "Choose Timeline:",
                                    "Enabled": False,
                                }
                            ),
                            ui.ComboBox(
                                {
                                    "ID": "PresetsCombo",
                                    "Text": "Choose Preset:",
                                }
                            ),
                        ],
                    ),
                    ui.HGroup(
                        [
                            ui.CheckBox(
                                {
                                    "Weight": 0,
                                    "ID": "CheckBox",
                                    "Text": "Override Timeline",
                                    "AlignmentFlag": "AlignRight",
                                }
                            ),
                        ]
                    ),
                    ui.HGroup(
                        [
                            ui.Label(
                                {
                                    "ID": "FileLabel",
                                    "Text": Path(self.queue_path).name
                                    or "Queue File Not Loaded!",
                                    "AlignmentFlag": "AlignRight",
                                }
                            ),
                        ]
                    ),
                    ui.HGroup(
                        [
                            ui.Button({"ID": "LoadButton", "Text": "Load Queue File"}),
                        ]
                    ),
                    ui.HGroup(
                        {"Alignment": {"AlignHRight": True}, "Weight": 0},
                        [
                            ui.Button(
                                {"ID": "RunButton", "Text": "Build Render Queue"}
                            ),
                            ui.Button({"ID": "CancelButton", "Text": "Cancel"}),
                        ],
                    ),
                ],
            ),
        ]

    def toggle_timelines(self, ev):
        self.itm["TimelinesCombo"].Enabled = self.itm["CheckBox"].Checked

    def load_queue_file(self, ev):
        queue_file = Path(app.RequestFile())
        if not queue_file.exists():
            print("Queue File does not exist!")
            return
        self.itm["FileLabel"].Text = queue_file.name
        app.SetData("RenderQueueFilePath", queue_file.as_posix())

    def process_queue(self, ev):
        override_timeline = self.itm["CheckBox"].Checked
        preset_name = self.itm["PresetsCombo"].CurrentText
        timeline_name = self.itm["TimelinesCombo"].CurrentText
        render_job_list = get_render_list()

        dialog = ConfirmationDialog(
            fusion=fu,
            title="Do you want to import the render queue?",
            info=[
                f"Preset selected: {preset_name}",
                f"Total Jobs to be loaded: {len(render_job_list)}",
            ],
        )
        confirmed = dialog.run()
        if not confirmed:
            print("Cancelled!")
            return
        build_queue(preset_name, timeline_name, override_timeline, render_job_list)
        disp.ExitLoop()


timelines = get_timelines()
timeline_name = project.GetCurrentTimeline().GetName()
LoadQueueUI(fu, timeline_name, title="Restore Render Queue").show()
