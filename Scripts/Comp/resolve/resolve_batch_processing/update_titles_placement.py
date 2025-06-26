"""
This script automates the process of updating title placements in Fusion compositions for clips in a given timeline track.
It utilizes Resolve and Fusion utilities to adjust various tool settings for both HD and SD file tools, as well as
positioning for placement, name, and song tools within the composition.
Main functionalities:
    - adjust_tools(comp):
        Modifies specific tool properties within a Fusion composition by:
            • Setting the pixel aspect ratio for the HD file tool and its custom aspect settings.
            • Adjusting the SD file tool's pixel aspect ratio.
            • Repositioning the 'place' tool by updating its center coordinates and scaling dimensions.
            • Adjusting the positioning and settings for 'name' and 'song' tools to apply frame format settings.
    - process_clips():
        Retrieves clips from track number 3 using a Resolve utility and prompts the user with a confirmation
        dialog. Upon confirmation, it iterates over the clips to process each Fusion composition by invoking the
        adjust_tools function.
Usage:
    Run the script directly to prompt for a confirmation and process the clips accordingly.
"""

from ui_utils import ConfirmationDialog
from resolve_utils import ResolveUtility

utils = ResolveUtility()


def adjust_tools(comp):

    hd_file_tool = comp.FindTool("HD_File")
    hd_file_tool.PixelAspect[0] = 2
    hd_file_tool.CustomPixelAspect[0] = {1: 1, 2: 1, 3: 0}

    sd_file_tool = comp.FindTool("SD")
    sd_file_tool.PixelAspect[0] = {1: 1.0667, 2: 1, 3: 0}

    place_tool = comp.FindTool("place")
    place_tool.Center[0] = {1: 0.768817, 2: 0.634818558432059, 3: 0.0}
    place_tool.XSize[0] = 0.4397
    place_tool.YSize[0] = 0.444

    name_tool = comp.FindTool("name")
    name_tool.Center[0] = {1: 0.1096294238635, 2: 0.253214581497244, 3: 0.0}
    name_tool.UseFrameFormatSettings[0] = 1

    song_tool = comp.FindTool("song")
    song_tool.Center[0] = {1: 0.1096294238635, 2: 0.2080784082473, 3: 0.0}
    song_tool.UseFrameFormatSettings[0] = 1


def process_clips():
    """chante title HD checkbox"""

    clips = utils.get_clips_in_timeline(track_number=3)

    answer = ConfirmationDialog("Toggle", "Update Titles for HD?")
    if answer:
        for clip in clips:
            utils.process_fusion_comp(
                clip,
                process_functions=[adjust_tools],
            )


if __name__ == "__main__":
    process_clips()
