width = tool.GetAttrs('TOOLI_ImageWidth')
height = tool.GetAttrs('TOOLI_ImageHeight')

comp.SetPrefs({'Comp.FrameFormat.Width': width, 'Comp.FrameFormat.Height': height})

print('Comp size is adjusted to {}x{}'.format(int(width), int(height)))

