print('select multiple tools you want to conform and at least one loader.\nThen activate the loader by clicking it. ')
tools_to_conform = comp.GetToolList(True)

active_tool = comp.ActiveTool

if active_tool and active_tool.ID == 'Loader':
    attrs = active_tool.GetAttrs()
    width = attrs["TOOLIT_Clip_Width"][1]
    height = attrs["TOOLIT_Clip_Height"][1]

    try:
        aspect_x = attrs["TOOLN_ImageAspectX"]
        aspect_y = attrs["TOOLN_ImageAspectY"]
        aspect_list = [aspect_x, aspect_y]
        image_depth = attrs["TOOLI_ImageDepth"]
    except KeyError:
        comp.CurrentFrame.ViewOn(active_tool, 1)
        print(
            "\nWARNING: image was not loaded to the viewer, aspect and depth could not be set"
        )
        aspect_list = image_depth = None

    if aspect_list and image_depth:
        for tool in tools_to_conform.values():
            if tool.ID in ['PolylineMask', 'RectangleMask', 'EllipseMask']:
                tool.OutputSize = 'Custom'
                tool.MaskWidth = width
                tool.MaskHeight = height
            elif tool.ID == 'Background':
                tool.Width = width
                tool.Height = height
            tool.PixelAspect = aspect_list
            tool.Depth = image_depth - 4
        print('Done!')

    else:
        print('run the script once again to set image depth and aspect correctly')
else:
    print('Select Backgrounds and activate Loader')
