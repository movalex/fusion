#!/usr/bin/env python

"""
    This is a Davinci Resolve script will change each text+ tabs values
    Author: Alexey Bogomolov
    Email: mail@abogomolov.com
    License: MIT
    Copyright: 2022
"""

TABS_VALUES = [-0.01, 0.01]


def switch_text_tabs():
    """create stills from all clips in a timeline
    save the files to requested folder
    """
    if not fu.GetResolve():
        print("This is a script for Davinci Resolve")
        return

    project = resolve.GetProjectManager().GetCurrentProject()
    timeline = project.GetCurrentTimeline()
    clips = timeline.GetItemListInTrack("Video", 2)

    if len(clips) == 0:
        print("no stills saved")
        return

    for clip in clips:
        if clip.GetName() == "Transition":
            continue
        comp = clip.GetFusionCompByName("Composition 1")
        text = comp.FindTool("Template")
        text.Tab1Position[1] = TABS_VALUES[0]
        text.Tab3Position[1] = TABS_VALUES[1]


if __name__ == "__main__":
    switch_text_tabs()
