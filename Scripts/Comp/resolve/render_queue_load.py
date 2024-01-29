import json
import DaVinciResolveScript as dvr_script
from pathlib import Path
from resolve_utils import ConfirmationDialog


resolve = dvr_script.scriptapp("Resolve")
projectManager = resolve.GetProjectManager()
project = projectManager.GetCurrentProject()


def get_render_list():
    queue_file = Path("~/Desktop/render_queue.json").expanduser()
    if not queue_file.exists():
        print("Export the queue file with 'save_render_queue' function!")
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


def main(preset_name, timeline_name, timeline_name_override=None):
    if timeline_name_override is None:
        timeline_name_override = False
    render_job_list = get_render_list()
    if not render_job_list:
        print(f"Queue file not found!")
        return
    render_settings = {}
    timeline = project.GetCurrentTimeline()

    current_timelines = get_timelines()

    for n, job in enumerate(render_job_list):
        if not timeline_name_override:
            timeline_name = job["TimelineName"]
        timeline_idx = current_timelines.get(timeline_name)
        if not timeline_idx:
            print(f"Timeline name {timeline_name} not found in the jobs list")
            continue
        timeline = project.GetTimelineByIndex(timeline_idx)
        project.SetCurrentTimeline(timeline)
        width = job["FormatWidth"]
        file_name = job.get("OutputFilename", f"OutputFile_{n}")
        render_job = project.AddRenderJob()
        print(f"Setting preset: {preset_name}")
        project.LoadRenderPreset(preset_name)
        render_settings["MarkIn"] = job["MarkIn"]
        render_settings["MarkOut"] = job["MarkOut"]
        render_settings["CustomName"] = file_name
        project.SetRenderSettings(render_settings)


def show_ui(timeline_name: str):
    ui = fu.UIManager
    disp = bmd.UIDispatcher(ui)
    win = disp.AddWindow(
        {
            "ID": "RestoreRenderQueue",
            "TargetID": "RestoreRenderQueue",
            "WindowTitle": "Restore Render Queue",
            "Geometry": [800, 600, 450, 120],
        },
        [
            ui.VGroup(
                [
                    ui.HGroup(
                        {"Weight": 0},
                        [
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
                            ui.ComboBox(
                                {
                                    "ID": "TimelinesCombo",
                                    "Text": "Choose Timeline:",
                                }
                            ),
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
                        {"Alignment": {"AlignHRight": True}, "Weight": 0},
                        [
                            ui.Button({"ID": "RunButton", "Text": "Import Queue"}),
                            ui.Button({"ID": "CancelButton", "Text": "Cancel"}),
                        ],
                    ),
                ],
            ),
        ],
    )
    itm = win.GetItems()

    preset_list = project.GetRenderPresetList()
    timelines = get_timelines()

    for preset in preset_list:
        itm["PresetsCombo"].AddItem(preset)
    for tl in timelines.keys():
        print(tl)
        itm["TimelinesCombo"].AddItem(tl)

    def cancel(ev):
        disp.ExitLoop()

    def import_queue(ev):
        dialog = ConfirmationDialog(fusion=fu, title="Do you want to import the render queue?")
        confirmed = dialog.run()
        if not confirmed:
            print("Cancelled!")
            return

        override_timeline = itm["CheckBox"].Checked
        preset_name = itm["PresetsCombo"].CurrentText
        timeline_name = itm["TimelinesCombo"].CurrentText
        main(preset_name, timeline_name, timeline_name_override=override_timeline)
        disp.ExitLoop()

    win.On.RunButton.Clicked = import_queue
    win.On.CancelButton.Clicked = cancel
    win.On.RestoreRenderQueue.Close = cancel

    win.Show()
    disp.RunLoop()
    win.Hide()


timelines = get_timelines()
timeline_name = project.GetCurrentTimeline().GetName()
show_ui(timeline_name)
