if tool.ID in ['Text3D', 'TextPlus']:
    text = tool.StyledText[1]
    text = text.lower()
    tool.StyledText[1] = text
