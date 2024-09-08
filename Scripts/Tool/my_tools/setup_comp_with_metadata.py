def convert_to_float(data: str):
    try:
        return float(data)
    except ValueError:
        print(f"The value {data} could not be converted to a number")
        return None


def set_comp_fps(value: float):
    comp.SetPrefs("Comp.FrameFormat.Rate", value)


def main(tool=None):
    if not tool:
        print("This is a Tool Script. Now trying to process currently active tool")
    tool = comp.ActiveTool
    if not tool:
        print(
            "No Active tool was found. Select a tool to read the metadata and run the script"
        )
        return

    tool_metadata = tool.Output[comp.CurrentTime].Metadata
    if not tool_metadata:
        print("No metadata found")
        return

    for key, value in tool_metadata.items():
        if "fps" in key.lower():
            fps_data = convert_to_float(value)
            if fps_data is not None:
                set_comp_fps(fps_data)
                print(f"Comp frame rate set to {fps_data} FPS")
                return

    print("No FPS information found in metadata")


if __name__ == "__main__":
    main(tool)
