#!/usr/bin/env python

"""
    ╔════════════════════════════════════════════════════════════════════╗
    ║                                                                    ║
    ║    DaVinci Resolve Text+ Version Switcher                          ║
    ║                                                                    ║
    ║    Description:                                                    ║
    ║      This script automates the process of switching between        ║
    ║      different versions of Text+ elements across multiple clips in ║
    ║      DaVinci Resolve. Ideal for workflows that require quick       ║
    ║      adjustments or batch updates to typography, color, or         ║
    ║      positioning in Fusion compositions.                           ║
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


VERSION = 2


def switch_version_and_adjust_spacing(comp):
    """create stills from all clips in a timeline
    save the files to requested folder
    """

    text = comp.FindTool("Template")
    if not text:
        return
    text.SetCurrentSettings(VERSION)
    text.CharacterSpacingClone[1] = 1


def process_clips(move_x: float):
    """Main function to process all clips in the timeline."""
    clips = utils.get_clips_in_timeline("Video", 3)
    if not clips:
        return

    answer = ConfirmationDialog("Move Position", "Do you want to move titles?")
    if answer:
        for clip in clips:
            utils.process_fusion_comp(
                clip,
                comp_name="Composition 4",
                process_functions=[switch_version_and_adjust_spacing],
            )


if __name__ == "__main__":
    process_clips()
