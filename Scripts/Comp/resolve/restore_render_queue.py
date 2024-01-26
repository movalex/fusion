import json
import DaVinciResolveScript as dvr_script
from pathlib import Path


resolve = dvr_script.scriptapp("Resolve")
projectManager = resolve.GetProjectManager()
project = projectManager.GetCurrentProject()
PRESETS = {720: "HQX SD", 1920: "HQX HD"}
QUEUE_FILE = Path("~/Desktop/render_queue.json").expanduser()


def save_render_queue():
    render_job_list = project.GetRenderJobList()
    with open(QUEUE_FILE, "w") as file:
        data = json.dump(render_job_list, file)
    return render_job_list


def get_render_list():
    if not QUEUE_FILE.exists():
        print("Export the queue file with 'save_render_queue' function!")
        return
    with open(QUEUE_FILE, "r", encoding="utf-8") as file:
        return json.load(file)


def main():
    render_settings = {}
    timeline = project.GetCurrentTimeline()
    timeline_count = project.GetTimelineCount()
    current_timelines = {}
    for i in range(1, timeline_count):
        timeline = project.GetTimelineByIndex(float(i))
        current_timelines[timeline.GetName()] = float(i)

    try:
        render_job_list = get_render_list()
    except Exception as e:
        print(f"Could not get the file queue\nError: {e}")
        return

    for n, job in enumerate(render_job_list):
        timeline_name = job["TimelineName"]
        timeline_idx = current_timelines.get(timeline_name)
        if not timeline_idx:
            print(f"Timeline name {timeline_name} not found in the jobs list")
            continue
        timeline = project.GetTimelineByIndex(timeline_idx)
        project.SetCurrentTimeline(timeline)
        width = job["FormatWidth"]
        preset = PRESETS[width]
        file_name = job.get("OutputFilename", f"OutputFile_{n}")
        render_job = project.AddRenderJob()
        print(f"Setting preset {preset}")
        project.LoadRenderPreset(preset)
        render_settings["MarkIn"] = job["MarkIn"]
        render_settings["MarkOut"] = job["MarkOut"]
        render_settings["CustomName"] = file_name
        project.SetRenderSettings(render_settings)


main()

# save_render_queue()
