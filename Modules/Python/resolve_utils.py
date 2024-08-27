"""
    Utility script for basic Scripting API operations in Davinci Resolve

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
from typing import Any
from get_resolve import GetResolve

resolve = GetResolve()


class ResolveUtility:
    def __init__(self):
        """
        Initialize the ResolveUtility with a resolve object.
        """
        self.resolve = resolve
        self.project_manager = self.resolve.GetProjectManager()

    def get_fusion_module(self):
        """
        Get the current Fusion instance.
        :return: The Fusion instance or None if not found.
        """
        return getattr(sys.modules["__main__"], "fusion", None)

    def reset_global_data(self, data: str):
        fusion = self.get_fusion_module()
        if fusion is None:
            raise RuntimeError("Fusion module not found.")
        print(f"Resetting data: [{data}]")
        fusion.SetData(data)

    def create_folder(self, folder_path: Path) -> None:
        try:
            folder_path.mkdir(exist_ok=True, parents=True)
        except PermissionError:
            print(f"Could not create target folder in {folder_path}")
            raise
        except FileNotFoundError:
            print("Wrong path is specified")
            raise
        
    def get_current_project(self):
        project = self.project_manager.GetCurrentProject()
        if project is None:
            raise RuntimeError("No current project found.")
        return project

    def get_current_timeline(self):
        project = self.get_current_project()
        return project.GetCurrentTimeline()

    def get_gallery(self):
        project = self.get_current_project()
        return project.GetGallery()

    def get_mediapool(self):
        project = self.get_current_project()
        return project.GetMediaPool()

    def get_timelines(self):
        project = self.get_current_project()
        timelines = {}
        timeline_count = self.project.GetTimelineCount()
        for i in range(1, timeline_count + 1):
            timeline = self.project.GetTimelineByIndex(float(i))
            timelines[timeline.GetName()] = float(i)
        return timelines

    def add_to_mediapool(self, file: list, subfolder_name=None):
        print(f"Importing {file}")
        pool = self.get_mediapool()
        if pool is None:
            raise RuntimeError("No media pool found.")
        root = pool.GetRootFolder()  
        if subfolder_name:
            folders = {folder.GetName(): folder for folder in root.GetSubFolderList()}
            if not subfolder_name in folders.keys():
                folder = pool.AddSubFolder(root, subfolder_name)
            else:
                folder = folders[subfolder_name]
        else:
            folder = root
        pool.SetCurrentFolder(folder)
        pool.ImportMedia(file)
