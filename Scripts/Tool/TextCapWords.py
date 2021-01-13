import string
if tool.ID in ['Text3D', 'TextPlus']:
    text = tool.StyledText[1]
    text = string.capwords(text)
    tool.StyledText[1] = text
