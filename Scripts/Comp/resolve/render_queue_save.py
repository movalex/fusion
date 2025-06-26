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

import json
from pathlib import Path
from ui_utils import BaseUI, RequestDir
from resolve_utils import ResolveUtility
from datetime import datetime


utils = ResolveUtility()


class ExportOptionsWindow(BaseUI):
    def __init__(self, title, max_jobs=1):
        self.title = title or "Export Render Jobs"
        self.max_jobs = max_jobs
        self.start_job = 1
        self.id = "ExportRenderJobsWindow"
        self.end_job = max_jobs
        geometry = [800, 650, 300, 90]
        super().__init__(self.title, geometry, id=self.id)
        self.itm = self.win.GetItems()
        self.result = None  # Store the result
        self.setup_callbacks()

    def layout(self):
        # Create the layout for start and end job selection
        return self.ui.VGroup(
            [
                self.ui.HGroup(
                    [
                        self.ui.Label(
                            {"Weight": 0.1, "ID": "StartJobLabel", "Text": "Start Job:"}
                        ),
                        self.ui.SpinBox(
                            {
                                "Weight": 0.4,
                                "ID": "StartJobSpinBox",
                                "Minimum": 1,
                                "Maximum": self.max_jobs,
                                "Value": self.start_job,
                                "Events": {"ValueChanged": True},
                            }
                        ),
                        self.ui.Label(
                            {"Weight": 0.1, "ID": "EndJobLabel", "Text": "End Job:"}
                        ),
                        self.ui.SpinBox(
                            {
                                "Weight": 0.4,
                                "ID": "EndJobSpinBox",
                                "Minimum": 1,
                                "Maximum": self.max_jobs,
                                "Value": self.end_job,
                                "Events": {"ValueChanged": True},
                            }
                        ),
                    ]
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

    def setup_callbacks(self):
        self.win.On.StartJobSpinBox.ValueChanged = self.update_start_job
        self.win.On.EndJobSpinBox.ValueChanged = self.update_end_job
        self.win.On.OkButton.Clicked = self.export_jobs
        self.win.On.CancelButton.Clicked = self.cancel

    def update_start_job(self, ev):
        self.start_job = self.itm["StartJobSpinBox"].Value
        if self.start_job > self.end_job:
            self.end_job = self.start_job
            self.itm["EndJobSpinBox"].Value = self.end_job

    def update_end_job(self, ev):
        self.end_job = self.itm["StartJobSpinBox"].Value
        if self.end_job < self.start_job:
            self.start_job = self.end_job
            self.itm["StartJobSpinBox"].Value = self.start_job

    def cancel(self, ev):
        self.result = None
        self.close()

    def export_jobs(self, ev):
        self.result = {
            "start_job": self.start_job,
            "end_job": self.end_job,
        }
        self.close()

    def run(self):
        self.show()
        return self.result  # Return the result after the window is closed


def save_render_queue():
    target_folder_data = app.GetData("RenderQueueData.TargetFolder")
    output_folder = RequestDir(
        title="Choose folder to export queue", target=target_folder_data
    )
    if not output_folder:
        return
    app.SetData("RenderQueueData.TargetFolder", output_folder)

    project = utils.get_current_project()
    render_job_list = project.GetRenderJobList()
    if not render_job_list:
        print("Render Queue list is empty, cancelling")
        return
    if not output_folder or not Path(output_folder).is_dir():
        print("Could not save the Render queue")
        return

    num_jobs = len(render_job_list)  # Get the total number of render jobs

    # Start the UI to allow the user to choose the range of jobs to export
    result = ExportOptionsWindow(
        title="Select Jobs to Export",
        max_jobs=num_jobs,
    ).run()

    if not result:
        return
    try:
        # Extract user-selected values
        start_job = result["start_job"]
        end_job = result["end_job"]
    except Exception:
        print("Render Jobs data not found")
        return

    # Prepare the list of jobs to export based on user selection. Convert to 0-based index
    jobs_to_export = render_job_list[start_job - 1 : end_job]

    queue_file = Path(
        output_folder, f"render_queue_{project.GetName()}_{start_job}-{end_job}_{datetime.now().date()}.json"
    )

    with open(queue_file, "w") as file:
        json.dump(jobs_to_export, file)

    print(f"Exported {len(jobs_to_export)} jobs to {queue_file}")


if __name__ == "__main__":

    save_render_queue()
