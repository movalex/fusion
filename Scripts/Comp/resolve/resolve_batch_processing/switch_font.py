#!/usr/bin/env python

"""
    This is a Davinci Resolve script switch text+ versions
    Author: Alexey Bogomolov
    Email: mail@abogomolov.com
    License: MIT
    Copyright: 2022
"""

FONT_STYLE = ["Mongoose"]


def switch_font():
    """create stills from all clips in a timeline
    save the files to requested folder
    """
    if not fu.GetResolve():
        print("This is a script for Davinci Resolve")
        return

    project = resolve.GetProjectManager().GetCurrentProject()
    timeline = project.GetCurrentTimeline()
    clips = timeline.GetItemListInTrack("Video", 10)

    if len(clips) == 0:
        print("no stills saved")
        return

    for clip in clips:
        print(f"changing font of {clip.GetName()} to {FONT_STYLE[0]}")
        comp = clip.GetFusionCompByName("Composition 1")
        text = comp.FindTool("NSC_Credits")
        text.Input2[1] = FONT_STYLE[0]


if __name__ == "__main__":
    switch_font()
