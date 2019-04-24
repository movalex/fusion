def main(tool):
    attrs = tool.GetAttrs()
    width = attrs['TOOLIT_Clip_Width'][1]
    height = attrs['TOOLIT_Clip_Height'][1]

    comp.SetPrefs({'Comp.FrameFormat.Width': width, 'Comp.FrameFormat.Height': height})

    print('Comp size is adjusted to {}x{}'.format(int(width), int(height)))

    try:
        aspect_x = attrs['TOOLN_ImageAspectX']
        aspect_y = attrs['TOOLN_ImageAspectY']
    except KeyError:
        print('To set pixel aspect ratio, add the Loader to the viewer')
        aspect_x = aspect_y = None
    if aspect_x and aspect_y:
        comp.SetPrefs({'Comp.FrameFormat.AspectX': aspect_x, 'Comp.FrameFormat.AspectY': aspect_y})
        print('Comp aspect is changed to {}:{}'.format(aspect_x, aspect_y))

    comp.SetPrefs({'Comp.FrameFormat.Name': 'Set by Script'})


if tool.ID == 'Loader':
    main(tool)
else:
    print('this tool script works with Loaders only')
