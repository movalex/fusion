
def main(tool):
    """
    Sets keyframes on the Blend parameter of a Merge node based on in/out points.
    The Blend will be set as:
      - 0.0 at (in_point - 1) and (out_point + 1)
      - 1.0 at (in_point) and (out_point)

    Parameters:
    node (Tool): The Fusion node to modify.
    """
    attrs = comp.GetAttrs()
    in_point = attrs["COMPN_RenderStart"]
    out_point = attrs["COMPN_RenderEnd"]

    # Define the keyframe positions and values
    frames = {
        in_point - 1: 0.0,  # Blend = 0 just before the in-point
        in_point: 1.0,  # Blend = 1 at the in-point
        out_point: 1.0,  # Blend = 1 at the out-point
        out_point + 1: 0.0,  # Blend = 0 just after the out-point
    }
    # Apply the keyframes
    for frame, value in frames.items():
        tool.Blend[frame] = value  # Set the Blend value
        # tool.Blend.SetKeyFrame(frame)  # Add a keyframe


if __name__ == "__main__":
    if not tool or tool.ID not in ["Merge", "Dissolve"]:
        print("Select Merge or Dissolve tool")
    else:
        main(tool)
