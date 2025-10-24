"""
    Script for extracting frame rate and image dimensions from metadata 
    and setting the composition's frame rate, pixel aspect, width, and height in Blackmagic Fusion.

    Copyright © 2024 Alexey Bogomolov
    Email: mail@abogomolov.com
    License: MIT
"""
from pprint import pprint
import BlackmagicFusion as bmd

fu = bmd.scriptapp("Fusion")
comp = fu.GetCurrentComp()


def convert_to_number(data: str, to_type):
    try:
        return to_type(data)
    except ValueError:
        print(f"The value {data} could not be converted to {to_type.__name__}")
        return None


def set_comp_pref(key: str, value):
    comp.SetPrefs(key, value)


def process_metadata(metadata, key_fragments):
    """
    Search for any of the key_fragments in the metadata keys (case-insensitive).
    Return the first found value that can be converted to float.
    """
    # Ensure key_fragments is a set of lowercase strings for fast lookup
    fragments = set(k.lower() for k in key_fragments)
    for key, value in metadata.items():
        key_lower = key.lower()
        for fragment in fragments:
            if fragment in key_lower:
                converted_value = convert_to_number(value, float)
                if converted_value is not None:
                    return converted_value
    return None


def set_from_background(tool):
    width = tool.Width[fu.TIME_UNDEFINED]
    height = tool.Height[fu.TIME_UNDEFINED]
    aspect_x, aspect_y, _ = tool.PixelAspect[fu.TIME_UNDEFINED].values()
    return width, height, aspect_x, aspect_y


def set_from_loader(tool):
    attrs = tool.GetAttrs()
    width = attrs["TOOLIT_Clip_Width"][1]
    height = attrs["TOOLIT_Clip_Height"][1]
    try:
        aspect_x = attrs["TOOLN_ImageAspectX"]
        aspect_y = attrs["TOOLN_ImageAspectY"]
    except KeyError:
        print(
            "Could not read pixel aspect ratio\nAdd the Loader to the viewer and try again"
        )
        aspect_x = aspect_y = None
    return width, height, aspect_x, aspect_y


def set_comp_size_and_aspect(width, height, aspect_x=None, aspect_y=None):
    set_comp_pref("Comp.FrameFormat.Width", width)
    set_comp_pref("Comp.FrameFormat.Height", height)
    print("Comp size is set to {}x{}".format(int(width), int(height)))
    if aspect_x and aspect_y:
        set_comp_pref("Comp.FrameFormat.AspectX", aspect_x)
        set_comp_pref("Comp.FrameFormat.AspectY", aspect_y)
        print("Comp pixel aspect is set to {}:{}".format(aspect_x, aspect_y))
    set_comp_pref("Comp.FrameFormat.Name", "Set by Script")


def main():
    tool = comp.ActiveTool
    if not tool:
        print("Select a tool to read the metadata or attributes")
        return

    if tool.ID == "Loader":
        print("Processing Loader tool...")
        width, height, aspect_x, aspect_y = set_from_loader(tool)
        print("Setting composition size and aspect ratio from Loader attributes...")
        set_comp_size_and_aspect(width, height, aspect_x, aspect_y)

        print("Processing tool metadata...")
        try:
            tool_metadata = tool.Output[comp.CurrentTime].Metadata
        except AttributeError:
            print(
                "Could not read tool's metadata.\nAdd the tool to the viewer and try again"
            )
        if not tool_metadata:
            print("No metadata found")
            return
        print("Tool metadata:")
        pprint(tool_metadata)
        # Pass a list of possible FPS key fragments
        fps_value = process_metadata(
            tool_metadata,
            ["fps", "framerate", "frame_rate", "frame rate"],
        )
        print(f"Frame Rate value found: {fps_value}")
        if fps_value is not None:
            set_comp_pref("Comp.FrameFormat.Rate", fps_value)
            print(f"FrameRate is set to {fps_value}")
        else:
            print("No framerate information found in metadata")

    elif tool.ID == "Background":
        print("Processing Background tool...")

        width, height, aspect_x, aspect_y = set_from_background(tool)
        set_comp_size_and_aspect(width, height, aspect_x, aspect_y)


if __name__ == "__main__":
    main()
