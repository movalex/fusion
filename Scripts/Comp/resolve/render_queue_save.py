"""
    This is a Davinci Resolve script to save render queues

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


import DaVinciResolveScript as dvr_script
import json
from pathlib import Path
from UI_utils import RequestDir
from resolve_utils import ResolveUtility
from datetime import datetime


resolve = dvr_script.scriptapp("Resolve")
utils = ResolveUtility(resolve)


def save_render_queue(folder_path):
    project = utils.get_current_project()
    queue_file = Path(folder_path, f"render_queue_{project.GetName()}_{datetime.now().date()}.json")
    render_job_list = project.GetRenderJobList()
    if not render_job_list:
        print("Render Queue list is empty, cancelling")
        return
    with open(queue_file, "w") as file:
        data = json.dump(render_job_list, file)
    return render_job_list


if __name__ == "__main__":
    output_folder = RequestDir(title="Choose folder to export queue")
    save_render_queue(folder_path=output_folder)