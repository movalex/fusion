#!/usr/bin/env python

"""
    ╔════════════════════════════════════════════════════════════════════╗
    ║                                                                    ║
    ║    DaVinci Resolve Batch Text+ Tabs switcher                       ║
    ║                                                                    ║
    ║    Description:                                                    ║
    ║      This script automates the process of switching Text+ tabs     ║
    ║      positions across a timeline in DaVinci Resolve. Ideal         ║
    ║      for batch modifications, such as repositioning or parameter   ║
    ║      changes, streamlining your workflow with precision and speed. ║
    ║                                                                    ║
    ║    Author: Alexey Bogomolov                                        ║
    ║    Contact: mail@abogomolov.com                                    ║
    ║    License: MIT                                                    ║
    ║    Copyright © 2022 Alexey Bogomolov                               ║
    ║                                                                    ║
    ║                                                                    ║
    ╚════════════════════════════════════════════════════════════════════╝
"""
from UI_utils import ConfirmationDialog
from resolve_utils import ResolveUtility
utils = ResolveUtility()


def switch_text_tabs(comp):
    """create stills from all clips in a timeline
    save the files to requested folder
    """
    tabs_values = [-0.01, 0.01]
    tool_name = "Template"
    modifications = {
        "Tab1Position": tabs_values[0],
        "Tab3Position": tabs_values[1],
    }
    utils.modify_tool_parameters(comp, tool_name, modifications)


def process_clips():
    """Main function to process all clips in the timeline."""
    clips = utils.get_clips_in_timeline("Video", 3)
    if not clips:
        return

    answer = ConfirmationDialog("Switch tabs", "Do you want to proceed?")
    if answer:
        for clip in clips:
            # if clip.GetName() == "Transition":
            #     continue
            utils.process_fusion_comp(clip, process_functions=[switch_text_tabs])


if __name__ == "__main__":
    process_clips()
