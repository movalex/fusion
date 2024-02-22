import DaVinciResolveScript as dvr_script
import json
from pathlib import Path
from resolve_utils import RequestDir
from datetime import datetime


resolve = dvr_script.scriptapp("Resolve")
projectManager = resolve.GetProjectManager()
project = projectManager.GetCurrentProject()


def save_render_queue(folder_path):
    queue_file = Path(folder_path, f"render_queue_{project.GetName()}_{datetime.now().date()}.json")
    render_job_list = project.GetRenderJobList()
    if not render_job_list:
        print("Render Queue list is empty, cancelling")
        return
    with open(queue_file, "w") as file:
        data = json.dump(render_job_list, file)
    return render_job_list


if __name__ == "__main__":
    output_folder = RequestDir(fu, title="Choose folder to export queue").run()
    save_render_queue(folder_path=output_folder)