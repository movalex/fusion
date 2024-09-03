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
    ║    Copyright © 2024 Alexey Bogomolov                               ║
    ║                                                                    ║
    ║                                                                    ║
    ╚════════════════════════════════════════════════════════════════════╝
"""
from UI_utils import ConfirmationDialog
from resolve_utils import ResolveUtility

utils = ResolveUtility()


def adjust_tools(comp):

    tool_name = "Rectangle2"
    modifications = {
        "Height": 0.0902537772703,
    }
    utils.modify_tool_parameters(comp, tool_name, modifications)


def process_clips():
    """Main function to process all clips in the timeline."""
    clips = utils.get_clips_in_timeline(track_type="Video", track_number=4)
    if not clips:
        return

    answer = ConfirmationDialog("Adjust Height")
    if answer:
        for clip in clips:
            utils.process_fusion_comp(clip, process_functions=[adjust_tools])


if __name__ == "__main__":
    process_clips()
