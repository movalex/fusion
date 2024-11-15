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

FONT_COLOR = 0.2117647058824
FONT_STYLE = "Microsoft Sans Serif"


def process(comp):
    """
    switch font im the credits
    """

    tool_name = "Template"

    modifications = {
        "Size": 0.08,
        # "Font": FONT_STYLE,
        # "Red3": FONT_COLOR,
        # "Green3": FONT_COLOR,
        # "Blue3": FONT_COLOR,
        # "ShadingMappingAspect1": 1.25,
    }
    utils.modify_tool_parameters(comp, tool_name, modifications)


def process_clips():
    """Main function to process all clips in the timeline."""
    clips = utils.get_clips_in_timeline("Video", 4)
    if not clips:
        return

    answer = ConfirmationDialog(
        "Switching font", f"Do you want switch font to {FONT_STYLE}?"
    )
    if answer:
        for clip in clips:
            utils.process_fusion_comp(clip, process_functions=[process])


if __name__ == "__main__":
    process_clips()
