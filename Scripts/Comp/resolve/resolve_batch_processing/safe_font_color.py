#!/usr/bin/env python

"""
    ╔════════════════════════════════════════════════════════════════════╗
    ║                                                                    ║
    ║    DaVinci Resolve batch change font color script                  ║
    ║                                                                    ║
    ║    Description:                                                    ║
    ║      This script automates the process of switching fonts colors   ║
    ║      across multiple clips in DaVinci Resolve, allowing for        ║
    ║      batch changes  Fusion compositions and Text+ elements.        ║
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

SAFE_COLOR = 0.92156862745098


def change_font_color(comp):
    """
    switch font im the credits
    """

    text = comp.FindTool("Template")
    if not text:
        return
    text.Red1[1] = SAFE_COLOR
    text.Green1[1] = SAFE_COLOR
    text.Blue1[1] = SAFE_COLOR


def process_clips():
    """Main function to process all clips in the timeline."""
    clips = utils.get_clips_in_timeline("Video", 9)
    if not clips:
        return

    answer = ConfirmationDialog(
        "Switching font", f"Do you want switch font to {SAFE_COLOR}?"
    )
    if answer:
        for clip in clips:
            utils.process_fusion_comp(clip, process_functions=[change_font_color])


if __name__ == "__main__":
    process_clips()
