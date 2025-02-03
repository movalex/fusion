"""
    Utility script for basic Scripting API operations in Davinci Resolve

    Copyright © 2024 Alexey Bogomolov
    Email: mail@abogomolov.com
    License: MIT
    
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
from log_utils import set_logging

log = set_logging(script_name="Resolve Utils")


class ResolveUtility:

    def __init__(self):
        self.resolve = None
        self.project_manager = None
        self.connect_to_resolve()

    def connect_to_resolve(self):
        """Initialize connection to DaVinci Resolve."""
        try:
            self.resolve = GetResolve()
            if not self.resolve:
                raise RuntimeError("Could not connect to DaVinci Resolve.")
            self.project_manager = self.resolve.GetProjectManager()
            if not self.project_manager:
                raise RuntimeError(
                    "Could not retrieve the Project Manager from DaVinci Resolve."
                )
        except Exception as e:
            self.handle_error(e)

    def handle_error(self, error):
        log.error(f"Error initializing DaVinci Resolve: {error}")
        log.info(
            "Please make sure DaVinci Resolve is running and the scripting module is available."
        )
        sys.exit(1)

    def get_fusion_module(self):
        """
        Get the current Fusion instance.
        """
        return getattr(sys.modules["__main__"], "fusion", None)

    def reset_global_data(self, data: str):
        fusion = self.get_fusion_module()
        if not fusion:
            raise RuntimeError("Fusion module not found.")
        log.debug(f"Resetting data: [{data}]")
        fusion.SetData(data)

    def create_folder(self, folder_path: Path) -> None:
        """Create a folder if it doesn't exist."""
        try:
            folder_path.mkdir(exist_ok=True, parents=True)
        except (PermissionError, FileNotFoundError) as e:
            log.warning(f"Could not create folder at {folder_path}: {e}")
            raise

    def get_current_project(self):
        project = self.project_manager.GetCurrentProject()
        if not project:
            raise RuntimeError("No current project found.")
        return project

    def get_timelines(self):
        """Retrieve all timelines in the current project."""
        project = self.get_current_project()
        timelines = {}
        for i in range(1, project.GetTimelineCount() + 1):
            timeline = project.GetTimelineByIndex(i)
            timelines[timeline.GetName()] = i
        return timelines
    
    def get_current_timeline(self):
        return self.get_current_project().GetCurrentTimeline()
    
    def get_current_clip(self):
        return self.get_current_timeline().GetCurrentVideoItem()

    def get_gallery(self):
        return self.get_current_project().GetGallery()

    def get_mediapool(self):
        return self.get_current_project().GetMediaPool()
    
    def get_current_fusion_composition(self, comp_name="Composition 1"):
        current_clip = self.get_current_clip()
        return self.get_fusion_composition(current_clip, comp_name)
    
    def get_fusion_composition(self, clip, comp_name="Composition 1"):
        """Retrieve a Fusion composition by name."""
        comp = clip.GetFusionCompByName(comp_name)
        return comp

    def get_clips_in_timeline(self, track_type="Video", track_number=3):
        """Get all clips in the specified timeline track."""
        timeline = self.get_current_timeline()
        if not timeline:
            log.debug("No timeline found in the project.")
            return []
        clips = timeline.GetItemListInTrack(track_type, track_number)
        if not clips:
            log.debug(f"No clips found in {track_type} track {track_number}.")
        return clips

    def add_to_mediapool(self, file: list, subfolder_name=None):
        """Add media files to the media pool, optionally in a subfolder."""
        pool = self.get_mediapool()
        if not pool:
            raise RuntimeError("No media pool found.")
        log.debug(f"Importing {file} to mediapool")
        root = pool.GetRootFolder()
        folder = root
        if subfolder_name:
            folders = {folder.GetName(): folder for folder in root.GetSubFolderList()}
            if subfolder_name not in folders:
                folder = pool.AddSubFolder(root, subfolder_name)
            else:
                folder = folders[subfolder_name]
        pool.SetCurrentFolder(folder)
        pool.ImportMedia(file)

    def process_fusion_comp(
        self, clip, comp_name="Composition 1", process_functions=None
    ):
        """Process the fusion composition in a clip using provided functions."""
        log.debug(f"Processing clip: {clip.GetName()}")
        comp = self.get_fusion_composition(clip, comp_name)
        if not comp:
            log.debug(f"No fusion composition found for clip: {clip.GetName()}")
            return

        if process_functions:
            for process_function in process_functions:
                process_function(comp)
        else:
            log.debug("No processing functions provided.")

    def modify_tool_parameters(self, comp, tool_name: str, modifications: dict):
        """
        Find a tool by its name in the composition and apply modifications.
        :param comp: The Fusion composition.
        :param tool_name: Name of the tool to find.
        :param modifications: A dictionary of tool attributes and their new values.
        """
        tool = comp.FindTool(tool_name)
        if tool:
            for attribute, value in modifications.items():
                try:

                    # Special handling for the "Center" attribute if it's a dictionary
                    if attribute == "Center" and isinstance(current_value, dict):
                        current_value = getattr(tool, attribute)[0]
                        # Merge the existing Center values with the new ones
                        updated_center = {
                            1: current_value.get(1, 0),
                            2: current_value.get(2, 0),
                            3: current_value.get(3, 0),
                        }
                        updated_center.update(value)  # Update with the new values
                        setattr(tool, attribute, updated_center)
                        log.debug(
                            f"Modified {tool_name}: {attribute} set to {updated_center}"
                        )
                    else:
                        # Directly set the attribute if it's not a dictionary
                        setattr(tool, attribute, value)
                        log.debug(f"Modified {tool_name}: {attribute} set to {value}")

                except AttributeError:
                    log.debug(
                        f"Error: {tool_name} does not have the attribute '{attribute}'"
                    )
        else:
            log.debug(f"Tool '{tool_name}' not found in the composition. Cancelling")
            sys.exit()


if __name__ == "__main__":
    resolve_util = ResolveUtility()
    if resolve_util.resolve:
        log.debug("Successfully connected to DaVinci Resolve.")
    else:
        log.debug("Could not connect to DaVinci Resolve.")
