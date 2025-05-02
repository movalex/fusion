comp_width = comp.GetPrefs()['Comp']['FrameFormat']['Width']
comp_height = comp.GetPrefs()['Comp']['FrameFormat']['Height']


for tool in comp.GetToolList(False, 'BetterResize').values():
    tool.Width[fu.TIME_UNDEFINED] = comp_width
    tool.Height[fu.TIME_UNDEFINED] = comp_width
    tool.KeepAspect[fu.TIME_UNDEFINED] = 1
