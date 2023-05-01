def set_from_background(tool):
    width = tool.Width[fu.TIME_UNDEFINED]
    height = tool.Height[fu.TIME_UNDEFINED]
    aspect_x, aspect_y, _ = tool.PixelAspect[fu.TIME_UNDEFINED].values()
    return width, height, aspect_x, aspect_y


def set_from_loader(tool):
    attrs = tool.GetAttrs()
    width = attrs['TOOLIT_Clip_Width'][1]
    height = attrs['TOOLIT_Clip_Height'][1]
    try:
        aspect_x = attrs['TOOLN_ImageAspectX']
        aspect_y = attrs['TOOLN_ImageAspectY']
    except KeyError:
        print('To set defaut pixel aspect ratio, add the Loader to the viewer')
        aspect_x = aspect_y = None
    return width, height, aspect_x, aspect_y


def main(args):
    width, height, aspect_x, aspect_y = args
    comp.SetPrefs({'Comp.FrameFormat.Width': width,
                   'Comp.FrameFormat.Height': height})
    print('Comp size is set to {}x{}'.format(int(width), int(height)))
    if aspect_x and aspect_y:
        comp.SetPrefs({'Comp.FrameFormat.AspectX': aspect_x,
                       'Comp.FrameFormat.AspectY': aspect_y})
        print('Comp pixel aspect is set to {}:{}'.format(aspect_x, aspect_y))
    comp.SetPrefs({'Comp.FrameFormat.Name': 'Set by Script'})


if tool.ID == 'Loader':
    payload = set_from_loader(tool)
    main(payload)
elif tool.ID == 'Background':
    payload = set_from_background(tool)
    main(payload)
else:
    print('this tool script works with Loaders only')
