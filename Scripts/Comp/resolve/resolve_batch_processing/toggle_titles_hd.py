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

from UI_utils import ConfirmationDialog, BaseUI
from resolve_utils import ResolveUtility

utils = ResolveUtility()


def toggle_hd_switch(comp):
    """Toggle the HD switch in a fusion tool."""
    tool = comp.FindTool("title_shtv")
    current_value = tool.switch_hd[0]
    new_value = 0 if current_value else 1
    tool.switch_hd[0] = new_value
    print(f"Toggled switch_hd from {current_value} to {new_value}")


def process_clips():
    """chante title HD checkbox"""

    clips = utils.get_clips_in_timeline(track_number=3)

    answer = ConfirmationDialog("Toggle", "Toggle HD checkbox?")
    if answer:
        for clip in clips:
            utils.process_fusion_comp(
                clip,
                process_functions=[toggle_hd_switch],
            )


if __name__ == "__main__":
    process_clips()
