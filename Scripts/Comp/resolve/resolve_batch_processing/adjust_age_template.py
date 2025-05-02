"""
Module: adjust_age_template
Updates Fusion composition parameters for the "Template" tool used in credits.
Retrieves clips, asks for user confirmation, and applies font/color modifications.
"""

from UI_utils import ConfirmationDialog
from resolve_utils import ResolveUtility
utils = ResolveUtility()

FONT_COLOR = 0.2117647058824
FONT_STYLE = "Microsoft Sans Serif"

def modify_tools(comp):
    """
    Modifies the parameters of a tool named "Template" in the given composition.

    Args:
        comp: The composition object where the tool parameters will be modified.

    Modifications:
        - Adjusts font size, style, and color.
        - Updates shading mapping aspect ratio.
        - Add any other necessary modifications here.
    """

    tools = {
        "Template": {
            "Size": 0.08,
            "Font": FONT_STYLE,
            "Red3": FONT_COLOR,
            "Green3": FONT_COLOR,
            "Blue3": FONT_COLOR,
            "ShadingMappingAspect1": 1.25,
        },
        # Add other tools with their modifications if needed
        # e.g., "AnotherTool": { ... }
    }

    for tool_name, modifications in tools.items():
        utils.modify_tool_parameters(comp, tool_name, modifications)

def main():
    """Main function to process all clips in the timeline."""
    clips = utils.get_clips_in_timeline("Video", 4)
    if not clips:
        return

    answer = ConfirmationDialog("Switching font", f"Do you want switch font to {FONT_STYLE}?")
    if answer:
        for clip in clips:
            utils.process_fusion_comp(clip, process_functions=[modify_tools])

if __name__ == "__main__":
    main()
