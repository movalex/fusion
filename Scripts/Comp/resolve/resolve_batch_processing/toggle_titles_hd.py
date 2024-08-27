#!/usr/bin/env python

"""
    This is a Davinci Resolve script switch text+ versions
    Author: Alexey Bogomolov
    Email: mail@abogomolov.com
    License: MIT
    Copyright: 2024
"""

from UI_utils import ConfirmationDialog, BaseUI

class ShowUI(BaseUI):
    pass


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

    answer = ConfirmationDialog("Toggle", "Do you toggle HD?")
    if answer:
        for clip in clips:
            print(f"Processing clip {clip.GetName()}")
            comp = clip.GetFusionCompByName("Composition 1")
            tool = comp.FindTool("title_shtv")
            mix = tool.switch_hd[0]
            if mix:
                tool.switch_hd[0] = 0
            else:
                tool.switch_hd[0] = 1

if __name__ == "__main__":
    process()
