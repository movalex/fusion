#!/usr/bin/env python

"""
    ╔════════════════════════════════════════════════════════════════════╗
    ║                                                                    ║
    ║    DaVinci Resolve Multi-Clip Font Switcher                        ║
    ║                                                                    ║
    ║    Description:                                                    ║
    ║      This script automates the process of switching fonts across   ║
    ║      multiple clips in DaVinci Resolve, allowing for batch changes ║
    ║      in Fusion compositions and Text+ elements. Ideal for creating ║
    ║      consistent typography across various versions of a timeline.  ║
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
FONT_STYLE = "Mongoose"


def switch_font(comp):
    """
    switch font im the credits
    """

    text = comp.FindTool("NSC_Credits")
    if not text:
        return
    text.Input2[1] = FONT_STYLE


def process_clips(move_x: float):
    """Main function to process all clips in the timeline."""
    clips = utils.get_clips_in_timeline("Video", 3)
    if not clips:
        return

    answer = ConfirmationDialog(
        "Switching font", f"Do you want switch font to {FONT_STYLE}?"
    )
    if answer:
        for clip in clips:
            utils.process_fusion_comp(process_functions=[switch_font])


if __name__ == "__main__":
    process_clips()
