#!/usr/bin/env python

"""
    ╔════════════════════════════════════════════════════════════════════╗
    ║                                                                    ║
    ║    DaVinci Resolve Batch Text+ Element Manipulator                 ║
    ║                                                                    ║
    ║    Description:                                                    ║
    ║      This script automates the process of adjusting multiple       ║
    ║      Text+ elements across a timeline in DaVinci Resolve. Ideal    ║
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



def move_title_text(comp):
    """Process tools in the fusion composition"""

    tool_name = "Instance_song_1"
    pos_x = 0.101687165725
    modifications = {"Center": {1: pos_x}}
    utils.modify_tool_parameters(comp, tool_name, modifications)


def process_clips(move_x: float):
    """Main function to process all clips in the timeline."""
    clips = utils.get_clips_in_timeline("Video", 3)
    if not clips:
        return

    answer = ConfirmationDialog("Move Position", "Do you want to move titles?")
    if answer:
        for clip in clips:
            utils.process_fusion_comp([
                move_title_text
            ])


if __name__ == "__main__":
    process_clips()
