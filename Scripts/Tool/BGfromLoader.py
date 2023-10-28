# BG from Loader script
# Create Background node from loader. Set Pixel aspect ratio and Bit Depth based on that Loader
# Author: Alexey Bogomolov
# version: 1.1 - 2023-10-27
# Lincense: MIT

tool = comp.ActiveTool
flow = comp.CurrentFrame.FlowView


def create_bg_from_loader(tool):
    attrs = tool.GetAttrs()
    width = attrs["TOOLI_ImageWidth"]
    height = attrs["TOOLI_ImageHeight"]
    posx, posy = flow.GetPosTable(tool).values()
    aspect_list = []
    image_depth = None

    try:
        aspect_x = attrs["TOOLN_ImageAspectX"]
        aspect_y = attrs["TOOLN_ImageAspectY"]
        aspect_list = [aspect_x, aspect_y]
        if aspect_list == [1.0, 2.0]:
            print("\nThe loader is probably interlaced, setting BG aspect to 1")
            aspect_list[1] = 1.0
        image_depth = attrs["TOOLI_ImageDepth"]
    except KeyError:
        print(
            "\nWARNING: image was not loaded to the viewer, aspect and depth could not"
            " be set"
        )
        if tool.GetAttrs()["TOOLBT_Clip_Loop"][1] == True:
            tool.Loop = 1
            comp.CurrentFrame.ViewOn(tool, 1)
            tool.Loop = 0
        else:
            comp.CurrentFrame.ViewOn(tool, 1)
            print(
                "\nCurrent tool is loaded to the viewer now"
                "\nTo get proper BG aspect and depth please run the script once again"
            )

    new_bg = comp.AddTool("Background", int(posx) + 1, int(posy) + 1)
    new_bg.Width = width
    new_bg.Height = height
    comp.SetActiveTool()
    # flow.Select(new_bg)

    if aspect_list and image_depth:
        depth_list = ["Default", "int8", "int16", "float16", "float32"]
        new_bg.PixelAspect = aspect_list
        new_bg.Depth = image_depth - 4
        print(
            "Created BG with Aspect {}:{} and Depth {}".format(
                aspect_list[0], aspect_list[1], depth_list[int(image_depth - 4)]
            )
        )


if __name__ == "__main__":
    if not tool:
        tool = comp.ActiveTool
    if tool.ID in ["Loader", "MediaIn"]:
        create_bg_from_loader(tool)
    else:
        print("this tool script works with Loaders only")
