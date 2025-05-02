#!/usr/bin/env python

"""
    ╔════════════════════════════════════════════════════════════════════╗
    ║                                                                    ║
    ║    DaVinci Resolve HD Toggle Automation                            ║
    ║                                                                    ║
    ║    Description:                                                    ║
    ║      This script automates the process of toggling the HD checkbox ║
    ║      across multiple elements in DaVinci Resolve. Ideal for        ║
    ║      batch-processing Text+ or Fusion compositions to quickly      ║
    ║      switch between SD and HD configurations.                      ║
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


def set_age_properties(comp):
    tools = {
        "Template": {
            "UseFrameFormatSettings": 1,
        },
        "Rectangle2": {"Height": 0.0834572846073},
    }
    for tool_name, modifications in tools.items():
        utils.modify_tool_parameters(comp, tool_name, modifications)


def toggle_hd_switch(comp):
    """Toggle the HD switch in a fusion tool."""
    tool = comp.FindTool("title_shtv")
    current_value = tool.switch_hd[0]
    new_value = 0 if current_value else 1
    tool.switch_hd[0] = new_value
    print(f"Toggled switch_hd from {current_value} to {new_value}")


def process_clips():
    """chante title HD checkbox"""

    track2_clips = utils.get_clips_in_timeline(track_number=2)
    track3_clips = utils.get_clips_in_timeline(track_number=3)

    answer = ConfirmationDialog("Toggle", "Toggle HD checkbox?")
    if answer:
        for clip in track2_clips:
            utils.process_fusion_comp(
                clip,
                process_functions=[toggle_hd_switch],
            )
        for clip in track3_clips:
            utils.process_fusion_comp(
                clip,
                process_functions=[set_age_properties],
            )


if __name__ == "__main__":
    process_clips()
