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
        geometry = ([800, 600, 450, 180],)
        super().__init__(fusion, title, geometry, id="LoadQueueWindow")
        sele.timeline_name = timeline_name
        self.setup_callbacks()
        self.itm = self.win.GetItems()

    def setup_callbacks(self):
        self.win.On.RunButton.Clicked = self.process_queue
        self.win.On.LoadButton.Clicked = self.load_queue_file
        self.win.On.CancelButton.Clicked = self.close
        self.win.On.RestoreRenderQueue.Close = self.close

    def fill_timelines(self):
        timelines = get_timelines()
        for tl in timelines.keys():
            self.itm["TimelinesCombo"].AddItem(tl)

    def layout(self):
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
                                    "Text": queue_path or "Queue File Not Loaded!",
                                    "AlignmentFlag": "AlignRight",
                                }
                            ),
                            ui.Button(
                                {"Weight": 0.1, "ID": "LoadButton", "Text": "Load"}
                            ),
                        ]
                    ),
                    ui.HGroup(
                        {"Alignment": {"AlignHRight": True}, "Weight": 0},
                        [
                            ui.Button({"ID": "RunButton", "Text": "Import Queue"}),
                            ui.Button({"ID": "CancelButton", "Text": "Cancel"}),
                        ],
                    ),
                ],
            ),
        ]

    def load_queue_file(self, ev):
        queue_file = Path(fu.RequestFile())
        if not queue_file.exists():
            print("Queue File does not exist!")
            return
        itm["FileLabel"].Text = queue_file.name
        app.SetData("RenderQueueFilePath", queue_file.as_posix())

    def process_queue(self, ev):
        dialog = ConfirmationDialog(
            fusion=fu, title="Do you want to import the render queue?"
        )
        confirmed = dialog.run()
        if not confirmed:
            print("Cancelled!")
            return

        override_timeline = itm["CheckBox"].Checked
        preset_name = itm["PresetsCombo"].CurrentText
        timeline_name = itm["TimelinesCombo"].CurrentText
        build_queue(preset_name, timeline_name, override_timeline)
        disp.ExitLoop()


def fill_custom_presets(itm) -> list:
    preset_list = project.GetRenderPresetList()
    cut_element = "Pro Tools"
    if cut_element in preset_list:
        index = preset_list.index(cut_element) + 1
        preset_list = preset_list[index:]

    for preset in preset_list:
        itm["PresetsCombo"].AddItem(preset)


def show_ui(timlelines: list, timeline_name: str):
    queue_path = app.GetData("RenderQueueFilePath")
    ui = fu.UIManager
    disp = bmd.UIDispatcher(ui)
    win = disp.AddWindow(
        {
            "ID": "RestoreRenderQueue",
            "TargetID": "RestoreRenderQueue",
            "WindowTitle": "Restore Render Queue",
            "Geometry": [800, 600, 450, 180],
        },
        [
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
                                    "Text": Path(queue_path).name or "Queue File Not Loaded!",
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
                            ui.Button({"ID": "RunButton", "Text": "Build"}),
                            ui.Button({"ID": "CancelButton", "Text": "Cancel"}),
                        ],
                    ),
                ],
            ),
        ],
    )
    itm = win.GetItems()

    timelines = get_timelines()

    fill_custom_presets(itm)

    for tl in timelines.keys():
        itm["TimelinesCombo"].AddItem(tl)

    def cancel(ev):
        disp.ExitLoop()

    def load_queue_file(ev):
        queue_file = Path(fu.RequestFile())
        if not queue_file.exists():
            print("file not exists")
            return
        itm["FileLabel"].Text = queue_file.name
        app.SetData("RenderQueueFilePath", queue_file.as_posix())

    def toggle_timelines(ev):
        itm["TimelinesCombo"].Enabled = itm["CheckBox"].Checked

    def process_queue(ev):
        override_timeline = itm["CheckBox"].Checked
        preset_name = itm["PresetsCombo"].CurrentText
        timeline_name = itm["TimelinesCombo"].CurrentText
        render_job_list = get_render_list()
        if not render_job_list:
            return
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

    win.On.CheckBox.Clicked = toggle_timelines
    win.On.RunButton.Clicked = process_queue
    win.On.LoadButton.Clicked = load_queue_file
    win.On.CancelButton.Clicked = cancel
    win.On.RestoreRenderQueue.Close = cancel

    win.Show()
    disp.RunLoop()
    win.Hide()


timelines = get_timelines()
timeline_name = project.GetCurrentTimeline().GetName()
show_ui(timelines, timeline_name)
