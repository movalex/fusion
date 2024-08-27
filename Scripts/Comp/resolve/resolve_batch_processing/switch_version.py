#!/usr/bin/env python

"""
    This is a Davinci Resolve script switch text+ versions
    Author: Alexey Bogomolov
    Email: mail@abogomolov.com
    License: MIT
    Copyright: 2022
"""

VERSION = 2


def switch_version(version_number):
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
        print("no stills saved")
        return

    for clip in clips:
        print(f"changing version of {clip.GetName()} to {VERSION}")
        comp = clip.GetFusionCompByName("Composition 4")
        text = comp.FindTool("Template")
        text.SetCurrentSettings(VERSION)
        text.CharacterSpacingClone[1] = 1


if __name__ == "__main__":
    switch_version(VERSION)
