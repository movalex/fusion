#!/usr/bin/env python

"""
    This is a Davinci Resolve script switch text+ versions
    Author: Alexey Bogomolov
    Email: mail@abogomolov.com
    License: MIT
    Copyright: 2024
"""

from UI_utils import ConfirmationDialog

pos_x = 0.101687165725


def process():
    """create stills from all clips in a timeline
    save the files to requested folder
    """
    if not fu.GetResolve():
        print("This is a script for Davinci Resolve")
        return

    project = resolve.GetProjectManager().GetCurrentProject()
    timeline = project.GetCurrentTimeline()
    clips = timeline.GetItemListInTrack("Video", 3)

    if len(clips) == 0:
        print("No clips found")
        return
    answer = ConfirmationDialog("Move Position", "Do you want to move positions?")
    if answer:
        for clip in clips:
            print(f"changing position for {clip.GetName()} to {pos_x}")
            comp = clip.GetFusionCompByName("Composition 1")
            tool = comp.FindTool("title_shtv")
            for node in tool.GetChildrenList().values():
                if node.Name.startswith("Instance_song"):
                    node_pos = node.Center[0]
                    node.Center[0] = {1: pos_x, 2: node_pos[2], 3: node_pos[3]}


if __name__ == "__main__":
    process()
