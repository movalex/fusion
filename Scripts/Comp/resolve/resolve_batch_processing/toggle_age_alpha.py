#!/usr/bin/env python

"""
    ╔═════════════════════════════════════════════════════════════════════╗
    ║                                                                     ║
    ║    DaVinci Resolve Batch Text+ Tool Adjuster                        ║
    ║                                                                     ║
    ║    Description:                                                     ║
    ║      This script automates the process of modifying multiple Text+  ║
    ║      elements in DaVinci Resolve, specifically adjusting parameters ║
    ║      in the Template and Merge tools within Fusion compositions.    ║
    ║      Ideal for batch-processing across multiple clips on the        ║
    ║      timeline.                                                      ║
    ║                                                                     ║
    ║    Author: Alexey Bogomolov                                         ║
    ║    Contact: mail@abogomolov.com                                     ║
    ║    License: MIT                                                     ║
    ║    Copyright © 2024 Alexey Bogomolov                                ║
    ║                                                                     ║
    ║                                                                     ║
    ╚═════════════════════════════════════════════════════════════════════╝
"""


from ui_utils import ConfirmationDialog
from resolve_utils import ResolveUtility

utils = ResolveUtility()


def modify_template_and_merge(comp):
    """
    Modify the Template, Merge1, and Background1 tools in the composition.
    """
    color = 0.121568627451
    pos_x = 0.17  # Assuming POS_X value for position adjustment
    tool_name = "Template"
    tool = comp.FindTool(tool_name)
    center = tool.Center[0]

    # Modifications for Template tool
    template_modifications = {
        "Size": 0.088,
        # "Center": {1: pos_x},  # Modify only the x position in the Center
        "Opacity1": 1,
        "Red3": color,
        "Green3": color,
        "Blue3": color,
        "ShadingGradient1": 1,  # this does not work properly, but at least can reset the gradient status
    }
    utils.modify_tool_parameters(comp, "Template", template_modifications)

    # Modifications for Merge1 tool
    merge_modifications = {
        "BlendClone": 0.65,
    }
    utils.modify_tool_parameters(comp, "Merge1", merge_modifications)

    # Modifications for Background1 tool
    background_modifications = {
        "PixelAspect": 1,
    }
    # utils.modify_tool_parameters(comp, "Background1", background_modifications)


def process_clips():
    """
    adjust text+ parameters
    """

    clips = utils.get_clips_in_timeline(track_number=4)

    answer = ConfirmationDialog("Alpha Adjust", "Do you want to process titles?")
    if answer:
        for clip in clips:
            utils.process_fusion_comp(
                clip,
                process_functions=[
                    modify_template_and_merge,
                ],
            )


if __name__ == "__main__":
    process_clips()
